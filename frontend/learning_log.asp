<!-- #include file="includes/header.asp" -->
<!-- #include file="includes/db_conn.asp" -->
<%
Dim dateFrom, dateTo, summaryJson, adjustJson, apiUrl
dateFrom    = Request.QueryString("date_from")
dateTo      = Request.QueryString("date_to")
summaryJson = GetAPI("/api/learning/summary")
apiUrl      = "/api/learning/adjustments?"
If dateFrom <> "" Then apiUrl = apiUrl & "date_from=" & dateFrom & "&"
If dateTo   <> "" Then apiUrl = apiUrl & "date_to="   & dateTo   & "&"
adjustJson  = GetAPI(apiUrl)
%>
<h1 class="text-xl font-bold mb-4">AI 學習記錄</h1>

<!-- 準確率趨勢 -->
<div class="bg-white shadow rounded p-5 mb-6">
  <h2 class="font-semibold mb-3">AI 準確率趨勢（近 30 批次）</h2>
  <div id="statsTable"><p class="text-sm text-gray-400">載入中...</p></div>
</div>

<!-- 人工調整記錄 -->
<div class="bg-white shadow rounded p-5">
  <div class="flex items-center justify-between mb-3">
    <h2 class="font-semibold">人工調整記錄</h2>
    <form method="get" class="flex gap-2">
      <input name="date_from" type="date" value="<%=dateFrom%>" class="border rounded px-2 py-1 text-sm">
      <span class="self-center text-gray-400">～</span>
      <input name="date_to"   type="date" value="<%=dateTo%>"   class="border rounded px-2 py-1 text-sm">
      <button type="submit" class="bg-gray-200 px-3 py-1 rounded text-sm hover:bg-gray-300">篩選</button>
    </form>
  </div>
  <div id="adjustTable"><p class="text-sm text-gray-400">載入中...</p></div>
</div>

<script>
// 準確率統計
const stats = <%=summaryJson%> || [];
const statsDiv = document.getElementById('statsTable');
if (stats.length === 0) {
  statsDiv.innerHTML = '<p class="text-gray-500 text-sm">尚無資料</p>';
} else {
  let html = `<table class="w-full text-sm border-collapse">
    <thead class="bg-blue-50 text-left">
      <tr>
        <th class="px-3 py-2 border-b">批次日期</th>
        <th class="px-3 py-2 border-b">總派單數</th>
        <th class="px-3 py-2 border-b">AI 直接確認</th>
        <th class="px-3 py-2 border-b">準確率</th>
      </tr>
    </thead><tbody>`;
  stats.forEach(s => {
    const pct = (s.accuracy_rate * 100).toFixed(1);
    const barColor = s.accuracy_rate >= 0.8 ? 'bg-green-400' : s.accuracy_rate >= 0.5 ? 'bg-yellow-400' : 'bg-red-400';
    html += `<tr>
      <td class="px-3 py-2 border-b">${s.batch_date}</td>
      <td class="px-3 py-2 border-b">${s.total_dispatches}</td>
      <td class="px-3 py-2 border-b">${s.ai_accepted}</td>
      <td class="px-3 py-2 border-b">
        <div class="flex items-center gap-2">
          <div class="w-24 bg-gray-200 rounded-full h-2">
            <div class="${barColor} h-2 rounded-full" style="width:${pct}%"></div>
          </div>
          <span class="font-semibold">${pct}%</span>
        </div>
      </td>
    </tr>`;
  });
  html += '</tbody></table>';
  statsDiv.innerHTML = html;
}

// 人工調整記錄
const adjustments = <%=adjustJson%> || [];
const adjustDiv = document.getElementById('adjustTable');
if (adjustments.length === 0) {
  adjustDiv.innerHTML = '<p class="text-gray-500 text-sm">尚無調整記錄</p>';
} else {
  const reasonLabels = {
    driver_leave: '司機休假', overload: '超載換車',
    customer_request: '客戶指定', region_mismatch: '地區不符',
    time_conflict: '時段衝突', other: '其他'
  };
  let html = `<table class="w-full text-sm border-collapse">
    <thead class="bg-gray-50 text-left">
      <tr>
        <th class="px-3 py-2 border-b">訂單</th>
        <th class="px-3 py-2 border-b">AI 建議</th>
        <th class="px-3 py-2 border-b">→ 人工修改</th>
        <th class="px-3 py-2 border-b">原因</th>
        <th class="px-3 py-2 border-b">調整時間</th>
      </tr>
    </thead><tbody>`;
  adjustments.forEach(a => {
    html += `<tr>
      <td class="px-3 py-2 border-b">${a.order_no||''}</td>
      <td class="px-3 py-2 border-b text-gray-500">${a.original_driver||''}</td>
      <td class="px-3 py-2 border-b font-medium">${a.adjusted_driver||''}</td>
      <td class="px-3 py-2 border-b">${reasonLabels[a.adjust_reason]||a.adjust_reason}</td>
      <td class="px-3 py-2 border-b text-gray-400">${a.adjusted_at?.slice(0,16)||''}</td>
    </tr>`;
  });
  html += '</tbody></table>';
  adjustDiv.innerHTML = html;
}
</script>
<!-- #include file="includes/footer.asp" -->
