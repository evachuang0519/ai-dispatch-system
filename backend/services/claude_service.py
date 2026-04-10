import os
import json
from typing import List, Dict, Any
import anthropic

MODEL = "claude-sonnet-4-20250514"
MAX_TOKENS = 2000
BATCH_SIZE = 20  # 每批最多處理訂單數


def build_learning_context(adjustments: List[Dict]) -> str:
    if not adjustments:
        return "（尚無人工調整記錄，將依一般原則派單）"
    lines = []
    for adj in adjustments:
        line = (
            f"地區={adj.get('region', '?')}、"
            f"時段={adj.get('scheduled_time', '?')}、"
            f"優先級={adj.get('priority', '?')} → "
            f"AI建議{adj.get('original_driver', '?')}，"
            f"人工改為{adj.get('adjusted_driver', '?')}"
            f"（原因：{adj.get('adjust_reason', '?')}）"
        )
        lines.append(line)
    return "\n".join(lines)


def build_prompt(orders: List[Dict], drivers: List[Dict], vehicles: List[Dict], learning_ctx: str) -> str:
    orders_text = json.dumps(orders, ensure_ascii=False, indent=2, default=str)
    drivers_text = json.dumps(drivers, ensure_ascii=False, indent=2, default=str)
    vehicles_text = json.dumps(vehicles, ensure_ascii=False, indent=2, default=str)

    return f"""以下是歷史人工調整記錄，請從中學習派單規律：
{learning_ctx}

請根據以下資料，為每筆待派訂單分配最合適的司機與車輛：

【待派訂單】
{orders_text}

【可用司機】
{drivers_text}

【可用車輛】
{vehicles_text}

請回傳 JSON 陣列，每個元素格式如下：
{{
  "order_id": <訂單ID>,
  "driver_id": <司機ID>,
  "vehicle_id": <車輛ID>,
  "confidence": <信心分數 0.0~1.0>,
  "reason": "<派單理由說明>"
}}

只回傳 JSON 陣列，不要其他說明文字。"""


SYSTEM_PROMPT = """你是一個專業的貨運派單助理。根據歷史派單規律、訂單需求（地區、時段、重量、優先級）
與可用資源（司機、車輛），為每筆訂單分配最合適的司機與車輛。
輸出格式必須是純 JSON 陣列，不含 markdown 或多餘說明。"""


async def run_dispatch(orders: List[Dict], drivers: List[Dict], vehicles: List[Dict],
                       adjustments: List[Dict]) -> List[Dict[str, Any]]:
    client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
    learning_ctx = build_learning_context(adjustments)
    results = []

    # 分批處理
    for i in range(0, len(orders), BATCH_SIZE):
        batch = orders[i:i + BATCH_SIZE]
        prompt = build_prompt(batch, drivers, vehicles, learning_ctx)

        message = client.messages.create(
            model=MODEL,
            max_tokens=MAX_TOKENS,
            system=SYSTEM_PROMPT,
            messages=[{"role": "user", "content": prompt}]
        )

        raw = message.content[0].text.strip()
        # 移除可能的 markdown code block
        if raw.startswith("```"):
            raw = raw.split("```")[1]
            if raw.startswith("json"):
                raw = raw[4:]
        parsed = json.loads(raw)
        results.extend(parsed)

    return results
