import re
from decimal import Decimal
from typing import Any, Dict, List, Optional

from fastapi import HTTPException
from sqlalchemy.orm import Session, joinedload

from app.core.config import settings
from app.models import Conversation, Message
from app.models.conversation import ConversationStatus
from app.models.message import MessageType
from app.models.order import OrderStatus, PaymentStatus, RefundSupportStatus
from app.services.cart_service import CartService
from app.services.chat_service import ChatService
from app.services.chatbot_catalog_service import ChatbotCatalogService
from app.services.discount_service import DiscountService
from app.services.openai_chat_service import OpenAIChatService
from app.services.order_service import OrderService


class ChatbotService:
    _HANDOFF_KEYWORDS = (
        "bao hanh",
        "khieu nai",
        "hoan tien",
        "refund",
        "thanh toan loi",
        "gap nhan vien",
        "gap admin",
    )
    _ORDER_LOOKUP_KEYWORDS = (
        "don hang",
        "ma don",
        "kiem tra don",
        "tra cuu don",
        "order",
        "giao den dau",
        "giao toi dau",
        "da giao chua",
        "trang thai don",
    )
    _DISCOUNT_LOOKUP_KEYWORDS = (
        "ma giam gia",
        "voucher",
        "coupon",
        "khuyen mai",
        "ma khuyen mai",
        "code giam",
        "code khuyen mai",
        "uu dai",
        "ma uu dai",
    )
    _GENERIC_DISCOUNT_CODE_TOKENS = {
        "code",
        "coupon",
        "discount",
        "giam",
        "giamgia",
        "khuyenmai",
        "ma",
        "nay",
        "nao",
        "uu",
        "uu dai",
        "voucher",
    }
    _ORDER_ID_PATTERN = re.compile(
        r"(?:#|ma\s*don|don|order)\s*#?\s*(\d{1,9})",
        re.IGNORECASE,
    )
    _DISCOUNT_CODE_PATTERN = re.compile(
        r"(?:ma|voucher|coupon|code)\s*(?:giam\s*gia|khuyen\s*mai|uu\s*dai)?\s*[:#-]?\s*([a-z0-9_-]{3,40})",
        re.IGNORECASE,
    )
    _ORDER_STATUS_LABELS = {
        OrderStatus.PENDING.value: "Đang chờ xử lý",
        OrderStatus.SHIPPING.value: "Đang giao hàng",
        OrderStatus.COMPLETED.value: "Đã giao thành công",
        OrderStatus.CANCELLED.value: "Đã hủy",
    }
    _PAYMENT_STATUS_LABELS = {
        PaymentStatus.UNPAID.value: "Chưa thanh toán",
        PaymentStatus.PAID.value: "Đã thanh toán",
    }
    _REFUND_STATUS_LABELS = {
        RefundSupportStatus.NONE.value: "Không có yêu cầu hỗ trợ thêm",
        RefundSupportStatus.CONTACT_REQUIRED.value: "Cần tư vấn viên hỗ trợ thêm",
        RefundSupportStatus.RESOLVED.value: "Đã được hỗ trợ",
    }

    @staticmethod
    def _normalize_text(value: Optional[str]) -> str:
        return ChatbotCatalogService._normalize_text(value)

    @staticmethod
    def _should_handoff(message_text: str) -> bool:
        normalized_text = ChatbotService._normalize_text(message_text)
        return any(keyword in normalized_text for keyword in ChatbotService._HANDOFF_KEYWORDS)

    @staticmethod
    def _should_lookup_order(message_text: str) -> bool:
        normalized_text = ChatbotService._normalize_text(message_text)
        return any(keyword in normalized_text for keyword in ChatbotService._ORDER_LOOKUP_KEYWORDS)

    @staticmethod
    def _should_lookup_discount(message_text: str) -> bool:
        normalized_text = ChatbotService._normalize_text(message_text)
        return any(keyword in normalized_text for keyword in ChatbotService._DISCOUNT_LOOKUP_KEYWORDS)

    @staticmethod
    def _extract_order_id(message_text: str) -> Optional[int]:
        normalized_text = ChatbotService._normalize_text(message_text)
        match = ChatbotService._ORDER_ID_PATTERN.search(normalized_text)
        if not match:
            return None
        try:
            return int(match.group(1))
        except (TypeError, ValueError):
            return None

    @staticmethod
    def _extract_discount_code(message_text: str) -> Optional[str]:
        normalized_text = ChatbotService._normalize_text(message_text)
        match = ChatbotService._DISCOUNT_CODE_PATTERN.search(normalized_text)
        if not match:
            return None

        code = (match.group(1) or "").strip().lower()
        if not code or code in ChatbotService._GENERIC_DISCOUNT_CODE_TOKENS:
            return None
        return code

    @staticmethod
    def _is_enabled() -> bool:
        return bool(settings.CHATBOT_ENABLED)

    @staticmethod
    def _load_recent_messages(
        db: Session,
        conversation: Conversation,
        limit: int = 6,
    ) -> List[Dict[str, str]]:
        rows = (
            db.query(Message)
            .options(joinedload(Message.media_items))
            .filter(
                Message.conversation_id == conversation.id,
                Message.deleted_at.is_(None),
            )
            .order_by(Message.id.desc())
            .limit(limit)
            .all()
        )
        rows.reverse()

        history: List[Dict[str, str]] = []
        for row in rows:
            serialized = ChatService.serialize_message(row)
            content = str(serialized.get("content") or "").strip()
            if not content:
                continue

            sender_role = serialized.get("sender_role")
            if not sender_role:
                sender_role = "user" if row.user_id == conversation.user_id else "admin"

            history.append(
                {
                    "sender_role": str(sender_role),
                    "content": content,
                }
            )
        return history

    @staticmethod
    def _find_existing_bot_reply(
        db: Session,
        conversation: Conversation,
        user_message_id: int,
    ) -> Optional[Message]:
        rows = (
            db.query(Message)
            .options(joinedload(Message.media_items))
            .filter(
                Message.conversation_id == conversation.id,
                Message.user_id == conversation.admin_id,
                Message.type == MessageType.SYSTEM,
                Message.deleted_at.is_(None),
                Message.id > user_message_id,
            )
            .order_by(Message.id.asc())
            .all()
        )
        for row in rows:
            metadata = ChatService._parse_message_metadata(row)
            if metadata.get("sender_role") != "bot":
                continue
            if metadata.get("reply_to_message_id") == user_message_id:
                return row
        return None

    @staticmethod
    def _build_product_payload(
        selected_products: List[Dict[str, Any]],
        follow_up_suggestions: List[str],
    ) -> Dict[str, Any]:
        return {
            "kind": "product_list",
            "title": "Gợi ý cho bạn",
            "products": [
                {
                    "product_id": item["product_id"],
                    "name": item["name"],
                    "image_url": item["image_url"],
                    "price": item["price"],
                    "short_description": item["short_description"],
                    "category_name": item["category_name"],
                    "variants": item["variants"],
                    "actions": item["actions"],
                }
                for item in selected_products
            ],
            "follow_up_suggestions": follow_up_suggestions[:3],
        }

    @staticmethod
    def _pick_products_for_reply(
        candidate_products: List[Dict[str, Any]],
        matched_product_ids: List[int],
    ) -> List[Dict[str, Any]]:
        products_by_id = {int(item["product_id"]): item for item in candidate_products}
        selected_products: List[Dict[str, Any]] = []
        seen_ids: set[int] = set()

        for product_id in matched_product_ids:
            if product_id in seen_ids:
                continue
            candidate = products_by_id.get(product_id)
            if not candidate:
                continue
            seen_ids.add(product_id)
            selected_products.append(candidate)

        if selected_products:
            return selected_products[: settings.CHATBOT_MAX_PRODUCTS]

        return candidate_products[: settings.CHATBOT_MAX_PRODUCTS]

    @staticmethod
    def _resolve_shipping_fee(order: Any) -> Decimal:
        ghn_shipments = getattr(order, "ghn_shipments", None) or []
        if not ghn_shipments:
            return Decimal("0")
        ordered_shipments = sorted(
            list(ghn_shipments),
            key=lambda item: (
                getattr(item, "created_at", None),
                getattr(item, "id", 0),
            ),
            reverse=True,
        )
        raw_fee = getattr(ordered_shipments[0], "shipping_fee", None)
        return Decimal(str(raw_fee or 0))

    @staticmethod
    def _build_order_payload(order: Any) -> Dict[str, Any]:
        status_value = getattr(getattr(order, "status", None), "value", getattr(order, "status", "pending"))
        payment_status_value = getattr(
            getattr(order, "payment_status", None),
            "value",
            getattr(order, "payment_status", "unpaid"),
        )
        refund_status_value = getattr(
            getattr(order, "refund_support_status", None),
            "value",
            getattr(order, "refund_support_status", "none"),
        )
        shipping_fee = ChatbotService._resolve_shipping_fee(order)
        items: List[Dict[str, Any]] = []
        subtotal = Decimal("0")

        for detail in getattr(order, "order_details", []) or []:
            unit_price = Decimal(str(getattr(detail, "price", 0) or 0))
            quantity = int(getattr(detail, "quantity", 0) or 0)
            subtotal += unit_price * quantity
            product_detail = getattr(detail, "product_detail", None)
            product = getattr(product_detail, "product", None)
            product_images = list(getattr(product, "product_images", []) or [])
            image_url = getattr(product_images[0], "url", None) if product_images else None

            items.append(
                {
                    "product_name": getattr(product, "name", "Sản phẩm"),
                    "image_url": image_url,
                    "color_name": getattr(getattr(product_detail, "color", None), "name", None),
                    "size_name": getattr(getattr(product_detail, "size", None), "size", None),
                    "quantity": quantity,
                    "unit_price": float(unit_price),
                }
            )

        total_amount = subtotal + shipping_fee
        delivery_info = getattr(order, "delivery_info", None)
        payment_method = getattr(order, "payment_method", None)

        return {
            "kind": "order_summary",
            "title": f"Đơn hàng #{order.id}",
            "order": {
                "order_id": order.id,
                "status": status_value,
                "status_label": ChatbotService._ORDER_STATUS_LABELS.get(status_value, status_value),
                "payment_status": payment_status_value,
                "payment_status_label": ChatbotService._PAYMENT_STATUS_LABELS.get(
                    payment_status_value,
                    payment_status_value,
                ),
                "refund_support_status": refund_status_value,
                "refund_support_status_label": ChatbotService._REFUND_STATUS_LABELS.get(
                    refund_status_value,
                    refund_status_value,
                ),
                "created_at": (
                    getattr(order, "created_at", None).isoformat()
                    if getattr(order, "created_at", None) is not None
                    else None
                ),
                "shipping_fee": float(shipping_fee),
                "total_amount": float(total_amount),
                "total_items": sum(int(item["quantity"]) for item in items),
                "payment_method_name": getattr(payment_method, "name", None),
                "recipient_name": getattr(delivery_info, "name", None),
                "recipient_phone": getattr(delivery_info, "phone", None),
                "delivery_address": getattr(delivery_info, "address", None),
                "items": items[:3],
            },
        }

    @staticmethod
    def _build_order_message(order: Any, requested_order_id: Optional[int]) -> str:
        status_value = getattr(getattr(order, "status", None), "value", getattr(order, "status", "pending"))
        payment_status_value = getattr(
            getattr(order, "payment_status", None),
            "value",
            getattr(order, "payment_status", "unpaid"),
        )
        order_label = ChatbotService._ORDER_STATUS_LABELS.get(status_value, status_value)
        payment_label = ChatbotService._PAYMENT_STATUS_LABELS.get(payment_status_value, payment_status_value)
        prefix = (
            f"Mình đã kiểm tra đơn #{order.id} của bạn."
            if requested_order_id is not None
            else f"Đơn gần nhất của bạn là #{order.id}."
        )
        return f"{prefix} Trạng thái hiện tại: {order_label}. Thanh toán: {payment_label}."

    @staticmethod
    def _build_discount_payload(
        discounts: List[Any],
        title: str,
        actions: List[Dict[str, Any]],
    ) -> Dict[str, Any]:
        return {
            "kind": "discount_list",
            "title": title,
            "discounts": [
                {
                    "discount_id": item.id,
                    "name": getattr(item, "name", "") or "",
                    "description": getattr(item, "description", None),
                    "percent": float(getattr(item, "percent", 0) or 0),
                    "status": getattr(getattr(item, "status", None), "value", getattr(item, "status", "")),
                    "category_id": getattr(item, "category_id", None),
                    "category_name": getattr(getattr(item, "category", None), "name", None),
                    "start_at": (
                        getattr(item, "start_at", None).isoformat()
                        if getattr(item, "start_at", None) is not None
                        else None
                    ),
                    "end_at": (
                        getattr(item, "end_at", None).isoformat()
                        if getattr(item, "end_at", None) is not None
                        else None
                    ),
                }
                for item in discounts
            ],
            "actions": actions,
        }

    @staticmethod
    def _generate_discount_reply(
        db: Session,
        conversation: Conversation,
        user_message_id: int,
        cleaned_content: str,
    ) -> Message:
        requested_code = ChatbotService._extract_discount_code(cleaned_content)
        discounts: List[Any] = []
        source = "general"

        if requested_code is not None:
            discount = DiscountService.get_valid_discount(db, code_name=requested_code)
            if not discount:
                return ChatService.create_bot_message(
                    db=db,
                    conversation_id=conversation.id,
                    content=(
                        f"Mình chưa tìm thấy mã giảm giá `{requested_code.upper()}` còn hiệu lực. "
                        "Bạn có thể kiểm tra lại mã hoặc mở kho voucher để xem các mã đang áp dụng."
                    ),
                    reply_to_message_id=user_message_id,
                )
            discounts = [discount]
            source = "code"
        else:
            cart = CartService.get_cart(db, conversation.user_id)
            cart_category_ids = list(
                {
                    int(category_id)
                    for detail in getattr(cart, "cart_details", []) or []
                    for category_id in [
                        getattr(
                            getattr(getattr(detail, "product_detail", None), "product", None),
                            "category_id",
                            None,
                        )
                    ]
                    if isinstance(category_id, int)
                }
            )

            candidate_products: List[Dict[str, Any]] = []
            category_ids = cart_category_ids
            if category_ids:
                source = "cart"
            else:
                candidate_products = ChatbotCatalogService.search_products(
                    db=db,
                    query=cleaned_content,
                    limit=settings.CHATBOT_MAX_PRODUCTS,
                )
                category_ids = list(
                    {
                        int(category_id)
                        for item in candidate_products
                        for category_id in [item.get("category_id")]
                        if isinstance(category_id, int)
                    }
                )
                if category_ids:
                    source = "query"

            if category_ids:
                discounts = list(
                    DiscountService.get_valid_discounts_by_category_ids(
                        db,
                        category_ids=category_ids,
                    ).values()
                )
            if not discounts:
                discounts = DiscountService.get_active_discounts(
                    db=db,
                    limit=settings.CHATBOT_MAX_PRODUCTS,
                )
                source = "general"

        discounts = sorted(
            discounts,
            key=lambda item: (
                -float(getattr(item, "percent", 0) or 0),
                getattr(item, "end_at", None) or getattr(item, "start_at", None),
                -int(getattr(item, "id", 0) or 0),
            ),
        )[: settings.CHATBOT_MAX_PRODUCTS]

        if not discounts:
            return ChatService.create_bot_message(
                db=db,
                conversation_id=conversation.id,
                content="Hiện tại chưa có mã giảm giá nào còn hiệu lực phù hợp với yêu cầu của bạn.",
                reply_to_message_id=user_message_id,
            )

        actions = [
            {
                "type": "open_vouchers",
                "label": "Xem kho voucher",
                "target": "/profile/vouchers",
            }
        ]
        if source == "cart":
            actions.insert(
                0,
                {
                    "type": "open_cart",
                    "label": "Mở giỏ hàng",
                    "target": "/cart",
                },
            )

        first_discount = discounts[0]
        first_category_name = getattr(getattr(first_discount, "category", None), "name", None)
        if requested_code is not None:
            content = (
                f"Mã giảm giá {getattr(first_discount, 'name', '').upper()} đang còn hiệu lực. "
                f"Ưu đãi hiện tại là giảm {float(getattr(first_discount, 'percent', 0) or 0):g}%"
                + (
                    f" cho danh mục {first_category_name}."
                    if (first_category_name or "").strip()
                    else "."
                )
            )
            title = f"Mã giảm giá {getattr(first_discount, 'name', '').upper()}"
        elif source == "cart":
            content = "Mình tìm được một số mã giảm giá đang áp dụng cho các sản phẩm trong giỏ hàng của bạn."
            title = "Mã giảm giá cho giỏ hàng"
        elif source == "query":
            content = "Mình tìm được một số mã giảm giá phù hợp với nhóm sản phẩm bạn đang quan tâm."
            title = "Mã giảm giá phù hợp"
        else:
            content = "Hiện shop đang có một số mã giảm giá còn hiệu lực mà bạn có thể tham khảo."
            title = "Mã giảm giá đang áp dụng"

        return ChatService.create_bot_message(
            db=db,
            conversation_id=conversation.id,
            content=content,
            payload=ChatbotService._build_discount_payload(
                discounts=discounts,
                title=title,
                actions=actions,
            ),
            reply_to_message_id=user_message_id,
        )

    @staticmethod
    def _generate_order_reply(
        db: Session,
        conversation: Conversation,
        user_message_id: int,
        cleaned_content: str,
    ) -> Message:
        requested_order_id = ChatbotService._extract_order_id(cleaned_content)
        order = None

        if requested_order_id is not None:
            try:
                order = OrderService.get_order_byID(
                    db=db,
                    order_id=requested_order_id,
                    user_id=conversation.user_id,
                )
            except HTTPException as exc:
                if exc.status_code != 404:
                    raise
        else:
            orders = OrderService.get_orders(db=db, user_id=conversation.user_id)
            if orders:
                order = orders[0]

        if not order:
            fallback_text = (
                f"Mình chưa tìm thấy đơn #{requested_order_id} của bạn."
                if requested_order_id is not None
                else "Mình chưa tìm thấy đơn hàng nào gần đây của bạn."
            )
            return ChatService.create_bot_message(
                db=db,
                conversation_id=conversation.id,
                content=f"{fallback_text} Bạn có thể gửi mã đơn hàng để mình kiểm tra chính xác hơn.",
                reply_to_message_id=user_message_id,
            )

        return ChatService.create_bot_message(
            db=db,
            conversation_id=conversation.id,
            content=ChatbotService._build_order_message(order, requested_order_id),
            payload=ChatbotService._build_order_payload(order),
            reply_to_message_id=user_message_id,
        )

    @staticmethod
    def generate_reply_for_message(
        db: Session,
        conversation_id: int,
        user_message_id: int,
    ) -> Optional[Message]:
        if not ChatbotService._is_enabled():
            return None

        conversation = ChatService.get_or_404(
            db,
            Conversation,
            conversation_id,
            "Conversation not found",
        )
        user_message = (
            db.query(Message)
            .options(joinedload(Message.media_items))
            .filter(
                Message.id == user_message_id,
                Message.conversation_id == conversation_id,
            )
            .first()
        )
        if not user_message:
            return None

        if user_message.user_id != conversation.user_id:
            return None
        if user_message.type != MessageType.TEXT:
            return None
        if user_message.deleted_at is not None:
            return None

        cleaned_content = (user_message.content or "").strip()
        if not cleaned_content:
            return None
        if conversation.status == ConversationStatus.CLOSED:
            return None

        existing_reply = ChatbotService._find_existing_bot_reply(
            db=db,
            conversation=conversation,
            user_message_id=user_message_id,
        )
        if existing_reply:
            return existing_reply

        if ChatbotService._should_handoff(cleaned_content):
            return ChatService.activate_handoff(
                db=db,
                conversation_id=conversation_id,
                content="Mình sẽ chuyển cuộc trò chuyện này cho tư vấn viên để hỗ trợ bạn kỹ hơn.",
                notice_message="Tư vấn viên sẽ tham gia cuộc trò chuyện sớm nhất có thể.",
                reply_to_message_id=user_message_id,
            )

        if ChatbotService._should_lookup_discount(cleaned_content):
            return ChatbotService._generate_discount_reply(
                db=db,
                conversation=conversation,
                user_message_id=user_message_id,
                cleaned_content=cleaned_content,
            )

        if ChatbotService._should_lookup_order(cleaned_content):
            return ChatbotService._generate_order_reply(
                db=db,
                conversation=conversation,
                user_message_id=user_message_id,
                cleaned_content=cleaned_content,
            )

        candidate_products = ChatbotCatalogService.search_products(
            db=db,
            query=cleaned_content,
            limit=settings.CHATBOT_MAX_PRODUCTS,
        )
        if not candidate_products:
            return None

        recent_messages = ChatbotService._load_recent_messages(
            db=db,
            conversation=conversation,
            limit=6,
        )
        llm_reply = OpenAIChatService.generate_product_reply(
            user_message=cleaned_content,
            recent_messages=recent_messages,
            candidate_products=[item["llm_candidate"] for item in candidate_products],
        )
        selected_products = ChatbotService._pick_products_for_reply(
            candidate_products=candidate_products,
            matched_product_ids=llm_reply.get("matched_product_ids") or [],
        )
        if not selected_products:
            return None

        message_text = str(llm_reply.get("message") or "").strip()
        if not message_text:
            message_text = "Mình tìm được một số sản phẩm có thể phù hợp với nhu cầu của bạn."

        return ChatService.create_bot_message(
            db=db,
            conversation_id=conversation.id,
            content=message_text,
            payload=ChatbotService._build_product_payload(
                selected_products=selected_products,
                follow_up_suggestions=llm_reply.get("follow_up_suggestions") or [],
            ),
            reply_to_message_id=user_message_id,
        )
