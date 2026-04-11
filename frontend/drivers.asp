<%@ CodePage=65001 %>
<!-- #include file="includes/header.asp" -->
<!-- #include file="includes/db_conn.asp" -->
<%
Dim regionFilter, activeFilter, searchName, apiUrl
regionFilter = Request.QueryString("region")
activeFilter = Request.QueryString("active")
searchName   = Request.QueryString("name")

apiUrl = "/api/drivers?"
If regionFilter <> "" Then apiUrl = apiUrl & "region=" & Server.URLEncode(regionFilter) & "&"
If activeFilter <> "" Then apiUrl = apiUrl & "active=" & activeFilter & "&"

Dim jsonData
jsonData = GetAPI(apiUrl)
%>
<div class="flex items-center justify-between mb-4">
  <h1 class="text-xl font-bold">司機管理</h1>
  <a href="driver_edit.asp?mode=new" class="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700">＋ 新增司機</a>
</div>

<form method="get" class="flex gap-3 mb-4">
  <input name="name" value="<%=searchName%>" placeholder="搜尋姓名" class="border rounded px-3 py-1 text-sm">
  <select name="region" class="border rounded px-3 py-1 text-sm">
    <option value="">所有地區</option>
    <option value="北區" <%If regionFilter="北區" Then Response.Write "selected"%>>北區</option>
    <option value="中區" <%If regionFilter="中區" Then Response.Write "selected"%>>中區</option>
    <option value="南區" <%If regionFilter="南區" Then Response.Write "selected"%>>南區</option>
  </select>
  <select name="active" class="border rounded px-3 py-1 text-sm">
    <option value="">所有狀態</option>
    <option value="true" <%If activeFilter="true" Then Response.Write "selected"%>>啟用中</option>
    <option value="false" <%If activeFilter="false" Then Response.Write "selected"%>>已停用</option>
  </select>
  <button type="submit" class="bg-gray-200 px-4 py-1 rounded text-sm hover:bg-gray-300">搜尋</button>
</form>

<div id="tableContainer">
  <p class="text-sm text-gray-500">載入中...</p>
</div>

<script>
const data = <%=jsonData%>;
const search = "<%=searchName%>".toLowerCase();
const rows = Array.isArray(data) ? data.filter(d => !search || d.name.toLowerCase().includes(search)) : [];

const container = document.getElementById('tableContainer');
if (rows.length === 0) {
  container.innerHTML = '<p class="text-gray-500">無資料</p>';
} else {
  let html = `<table class="w-full text-sm border-collapse bg-white shadow rounded overflow-hidden">
    <thead class="bg-blue-50 text-left">
      <tr>
        <th class="px-4 py-2 border-b">姓名</th>
        <th class="px-4 py-2 border-b">電話</th>
        <th class="px-4 py-2 border-b">可操作車型</th>
        <th class="px-4 py-2 border-b">負責地區</th>
        <th class="px-4 py-2 border-b">狀態</th>
        <th class="px-4 py-2 border-b">操作</th>
      </tr>
    </thead><tbody>`;
  rows.forEach(d => {
    const rowClass = d.is_active ? '' : 'text-gray-400 bg-gray-50';
    html += `<tr class="${rowClass}">
      <td class="px-4 py-2 border-b">${d.name}</td>
      <td class="px-4 py-2 border-b">${d.phone||''}</td>
      <td class="px-4 py-2 border-b">${d.vehicle_type||''}</td>
      <td class="px-4 py-2 border-b">${d.region||''}</td>
      <td class="px-4 py-2 border-b">${d.is_active ? '<span class="text-green-600">啟用</span>' : '<span class="text-gray-400">停用</span>'}</td>
      <td class="px-4 py-2 border-b flex gap-2">
        <a href="driver_edit.asp?mode=edit&id=${d.id}" class="text-blue-600 hover:underline">編輯</a>
        <button onclick="toggleDriver(${d.id})" class="text-orange-500 hover:underline">${d.is_active ? '停用' : '啟用'}</button>
      </td>
    </tr>`;
  });
  html += '</tbody></table>';
  container.innerHTML = html;
}

async function toggleDriver(id) {
  if (!confirm('確定要切換此司機狀態？')) return;
  const res = await fetch(API_BASE + '/api/drivers/' + id + '/toggle', {method:'PATCH'});
  if (res.ok) location.reload();
  else alert('操作失敗');
}
</script>
<!-- #include file="includes/footer.asp" -->
