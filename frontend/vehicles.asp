<!-- #include file="includes/header.asp" -->
<!-- #include file="includes/db_conn.asp" -->
<%
Dim typeFilter, activeFilter, apiUrl
typeFilter   = Request.QueryString("vehicle_type")
activeFilter = Request.QueryString("active")

apiUrl = "/api/vehicles?"
If typeFilter   <> "" Then apiUrl = apiUrl & "vehicle_type=" & Server.URLEncode(typeFilter) & "&"
If activeFilter <> "" Then apiUrl = apiUrl & "active=" & activeFilter & "&"

Dim jsonData
jsonData = GetAPI(apiUrl)
%>
<div class="flex items-center justify-between mb-4">
  <h1 class="text-xl font-bold">車輛管理</h1>
  <a href="vehicle_edit.asp?mode=new" class="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700">＋ 新增車輛</a>
</div>

<form method="get" class="flex gap-3 mb-4">
  <select name="vehicle_type" class="border rounded px-3 py-1 text-sm">
    <option value="">所有車型</option>
    <option value="小貨車" <%If typeFilter="小貨車" Then Response.Write "selected"%>>小貨車</option>
    <option value="大貨車" <%If typeFilter="大貨車" Then Response.Write "selected"%>>大貨車</option>
    <option value="冷凍車" <%If typeFilter="冷凍車" Then Response.Write "selected"%>>冷凍車</option>
  </select>
  <select name="active" class="border rounded px-3 py-1 text-sm">
    <option value="">所有狀態</option>
    <option value="true"  <%If activeFilter="true"  Then Response.Write "selected"%>>啟用中</option>
    <option value="false" <%If activeFilter="false" Then Response.Write "selected"%>>已停用</option>
  </select>
  <button type="submit" class="bg-gray-200 px-4 py-1 rounded text-sm hover:bg-gray-300">篩選</button>
</form>

<div id="tableContainer"><p class="text-sm text-gray-500">載入中...</p></div>

<script>
const data = <%=jsonData%>;
const rows = Array.isArray(data) ? data : [];
const container = document.getElementById('tableContainer');
if (rows.length === 0) {
  container.innerHTML = '<p class="text-gray-500">無資料</p>';
} else {
  let html = `<table class="w-full text-sm border-collapse bg-white shadow rounded overflow-hidden">
    <thead class="bg-blue-50 text-left">
      <tr>
        <th class="px-4 py-2 border-b">車牌</th>
        <th class="px-4 py-2 border-b">車型</th>
        <th class="px-4 py-2 border-b">最大載重(kg)</th>
        <th class="px-4 py-2 border-b">指派司機</th>
        <th class="px-4 py-2 border-b">狀態</th>
        <th class="px-4 py-2 border-b">操作</th>
      </tr>
    </thead><tbody>`;
  rows.forEach(v => {
    const rowClass = v.is_active ? '' : 'text-gray-400 bg-gray-50';
    html += `<tr class="${rowClass}">
      <td class="px-4 py-2 border-b">${v.plate_no}</td>
      <td class="px-4 py-2 border-b">${v.vehicle_type||''}</td>
      <td class="px-4 py-2 border-b">${v.max_weight||''}</td>
      <td class="px-4 py-2 border-b">${v.driver_name||'未指派'}</td>
      <td class="px-4 py-2 border-b">${v.is_active ? '<span class="text-green-600">啟用</span>' : '<span class="text-gray-400">停用</span>'}</td>
      <td class="px-4 py-2 border-b flex gap-2">
        <a href="vehicle_edit.asp?mode=edit&id=${v.id}" class="text-blue-600 hover:underline">編輯</a>
        <button onclick="toggleVehicle(${v.id})" class="text-orange-500 hover:underline">${v.is_active ? '停用' : '啟用'}</button>
      </td>
    </tr>`;
  });
  html += '</tbody></table>';
  container.innerHTML = html;
}

async function toggleVehicle(id) {
  if (!confirm('確定要切換此車輛狀態？')) return;
  const res = await fetch('/api/vehicles/' + id + '/toggle', {method:'PATCH'});
  if (res.ok) location.reload();
  else alert('操作失敗');
}
</script>
<!-- #include file="includes/footer.asp" -->
