<!-- #include file="includes/header.asp" -->
<!-- #include file="includes/db_conn.asp" -->
<%
Dim dateFrom, dateTo, workloadJson, apiUrl
dateFrom     = Request.QueryString("date_from")
dateTo       = Request.QueryString("date_to")
apiUrl       = "/api/reports/driver-workload?"
If dateFrom <> "" Then apiUrl = apiUrl & "date_from=" & dateFrom & "&"
If dateTo   <> "" Then apiUrl = apiUrl & "date_to="   & dateTo   & "&"
workloadJson = GetAPI(apiUrl)
%>
<div class="flex items-center justify-between mb-4">
  <h1 class="text-xl font-bold">派單報表</h1>
  <a href="/api/reports/export" class="border px-4 py-2 rounded text-sm hover:bg-gray-100">匯出 Excel</a>
</div>

<form method="get" class="flex gap-3 mb-6">
  <label class="self-center text-sm">期間</label>
  <input name="date_from" type="date" value="<%=dateFrom%>" class="border rounded px-3 py-1 text-sm">
  <span class="self-center text-gray-400">～</span>
  <input name="date_to"   type="date" value="<%=dateTo%>"   class="border rounded px-3 py-1 text-sm">
  <button type="submit" class="bg-gray-200 px-4 py-1 rounded text-sm hover:bg-gray-300">查詢</button>
</form>

<!-- 司機工作量 -->
<div class="bg-white shadow rounded p-5 mb-6">
  <h2 class="font-semibold mb-3">司機工作量統計</h2>
  <div id="workloadChart" class="space-y-2"></div>
</div>

<script>
const workload = <%=workloadJson%> || [];
const chartDiv = document.getElementById('workloadChart');

if (workload.length === 0) {
  chartDiv.innerHTML = '<p class="text-gray-500 text-sm">尚無資料</p>';
} else {
  const max = Math.max(...workload.map(w => w.dispatch_count), 1);
  workload.forEach(w => {
    const pct = Math.round(w.dispatch_count / max * 100);
    chartDiv.innerHTML += `
      <div class="flex items-center gap-3">
        <span class="w-20 text-sm text-right text-gray-600">${w.driver_name}</span>
        <div class="flex-1 bg-gray-100 rounded-full h-5 relative">
          <div class="bg-blue-500 h-5 rounded-full" style="width:${pct}%"></div>
        </div>
        <span class="w-10 text-sm font-semibold text-right">${w.dispatch_count}</span>
      </div>`;
  });
}
</script>
<!-- #include file="includes/footer.asp" -->
