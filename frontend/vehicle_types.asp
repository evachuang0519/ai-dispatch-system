<!-- #include file="includes/header.asp" -->
<!-- #include file="includes/db_conn.asp" -->
<%
Dim typesJson
typesJson = GetAPI("/api/vehicle-types")
%>
<div class="flex items-center justify-between mb-4">
  <h1 class="text-xl font-bold">車輛類型管理</h1>
  <a href="vehicles.asp" class="px-4 py-2 rounded border hover:bg-gray-100 text-sm">返回車輛管理</a>
</div>

<div class="flex gap-4 mb-6 items-end">
  <div>
    <label class="block text-sm font-medium mb-1">車型名稱</label>
    <input id="newName" type="text" placeholder="例：冷藏車" class="border rounded px-3 py-2 w-48">
  </div>
  <div>
    <label class="block text-sm font-medium mb-1">排序</label>
    <input id="newOrder" type="number" value="0" min="0" class="border rounded px-3 py-2 w-24">
  </div>
  <button onclick="addType()" class="bg-blue-600 text-white px-5 py-2 rounded hover:bg-blue-700">新增</button>
</div>

<table class="w-full max-w-lg bg-white shadow rounded text-sm">
  <thead class="bg-blue-50">
    <tr>
      <th class="px-4 py-2 text-left">車型名稱</th>
      <th class="px-4 py-2 text-left">排序</th>
      <th class="px-4 py-2 text-left">操作</th>
    </tr>
  </thead>
  <tbody id="typeList"></tbody>
</table>

<script>
let types = <%=typesJson%> || [];

function render() {
  const tbody = document.getElementById('typeList');
  if (types.length === 0) {
    tbody.innerHTML = '<tr><td colspan="3" class="px-4 py-4 text-gray-400 text-center">尚無車型</td></tr>';
    return;
  }
  tbody.innerHTML = types.map(t => `
    <tr class="border-t">
      <td class="px-4 py-2">${t.name}</td>
      <td class="px-4 py-2">${t.sort_order}</td>
      <td class="px-4 py-2">
        <button onclick="deleteType(${t.id},'${t.name}')"
          class="text-red-600 hover:underline text-sm">刪除</button>
      </td>
    </tr>`).join('');
}

async function addType() {
  const name = document.getElementById('newName').value.trim();
  const sort_order = parseInt(document.getElementById('newOrder').value) || 0;
  if (!name) { alert('請輸入車型名稱'); return; }
  const res = await fetch(API_BASE + '/api/vehicle-types', {
    method: 'POST',
    headers: {'Content-Type':'application/json'},
    body: JSON.stringify({name, sort_order})
  });
  if (res.ok) {
    const t = await res.json();
    types.push(t);
    types.sort((a,b) => a.sort_order - b.sort_order || a.id - b.id);
    document.getElementById('newName').value = '';
    render();
  } else if (res.status === 409) {
    alert('車型名稱已存在');
  } else {
    alert('新增失敗');
  }
}

async function deleteType(id, name) {
  if (!confirm(`確定要刪除「${name}」？`)) return;
  const res = await fetch(API_BASE + '/api/vehicle-types/' + id, {method:'DELETE'});
  if (res.ok) {
    types = types.filter(t => t.id !== id);
    render();
  } else {
    alert('刪除失敗');
  }
}

render();
</script>
<!-- #include file="includes/footer.asp" -->
