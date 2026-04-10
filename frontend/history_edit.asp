<!-- #include file="includes/header.asp" -->
<!-- #include file="includes/db_conn.asp" -->
<%
Dim mode, historyId, historyJson, driversJson, vehiclesJson
mode      = Request.QueryString("mode")
historyId = Request.QueryString("id")
historyJson = "null"
driversJson = GetAPI("/api/drivers?active=true")
vehiclesJson = GetAPI("/api/vehicles?active=true")

If mode = "edit" And historyId <> "" Then
    historyJson = GetAPI("/api/history/" & historyId)
End If
%>
<h1 class="text-xl font-bold mb-4"><%=If(mode="new","新增歷史派單","編輯歷史派單")%></h1>

<form id="historyForm" class="max-w-xl bg-white shadow rounded p-6 space-y-4">
  <div class="grid grid-cols-2 gap-4">
    <div>
      <label class="block text-sm font-medium mb-1">訂單編號 <span class="text-red-500">*</span></label>
      <input id="order_no" type="text" required class="w-full border rounded px-3 py-2">
    </div>
    <div>
      <label class="block text-sm font-medium mb-1">客戶名稱</label>
      <input id="customer_name" type="text" class="w-full border rounded px-3 py-2">
    </div>
    <div class="col-span-2">
      <label class="block text-sm font-medium mb-1">地址</label>
      <input id="address" type="text" class="w-full border rounded px-3 py-2">
    </div>
    <div>
      <label class="block text-sm font-medium mb-1">地區</label>
      <select id="region" class="w-full border rounded px-3 py-2">
        <option value="">請選擇</option>
        <option value="北區">北區</option>
        <option value="中區">中區</option>
        <option value="南區">南區</option>
      </select>
    </div>
    <div>
      <label class="block text-sm font-medium mb-1">預定時段</label>
      <input id="scheduled_time" type="datetime-local" class="w-full border rounded px-3 py-2">
    </div>
    <div>
      <label class="block text-sm font-medium mb-1">貨物重量 (kg)</label>
      <input id="weight" type="number" min="0" class="w-full border rounded px-3 py-2">
    </div>
    <div>
      <label class="block text-sm font-medium mb-1">優先級 (1=最高)</label>
      <input id="priority" type="number" min="1" max="5" value="3" class="w-full border rounded px-3 py-2">
    </div>
    <div>
      <label class="block text-sm font-medium mb-1">派單司機</label>
      <select id="driver_name" class="w-full border rounded px-3 py-2">
        <option value="">請選擇</option>
      </select>
    </div>
    <div>
      <label class="block text-sm font-medium mb-1">車牌號碼</label>
      <select id="plate_no" class="w-full border rounded px-3 py-2">
        <option value="">請選擇</option>
      </select>
    </div>
    <div class="col-span-2">
      <label class="block text-sm font-medium mb-1">備註</label>
      <textarea id="note" rows="2" class="w-full border rounded px-3 py-2"></textarea>
    </div>
  </div>
  <div class="flex gap-3">
    <button type="submit" class="bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700">儲存</button>
    <a href="history_manage.asp" class="px-6 py-2 rounded border hover:bg-gray-100">取消</a>
  </div>
</form>

<script>
const mode       = "<%=mode%>";
const historyId  = "<%=historyId%>";
const history    = <%=historyJson%>;
const drivers    = <%=driversJson%> || [];
const vehicles   = <%=vehiclesJson%> || [];

const driverSel  = document.getElementById('driver_name');
const vehicleSel = document.getElementById('plate_no');
drivers.forEach(d  => driverSel.appendChild(new Option(d.name, d.name)));
vehicles.forEach(v => vehicleSel.appendChild(new Option(v.plate_no, v.plate_no)));

if (history) {
  document.getElementById('order_no').value        = history.order_no || '';
  document.getElementById('customer_name').value   = history.customer_name || '';
  document.getElementById('address').value         = history.address || '';
  document.getElementById('region').value          = history.region || '';
  document.getElementById('scheduled_time').value  = history.scheduled_time ? history.scheduled_time.slice(0,16) : '';
  document.getElementById('weight').value          = history.weight || '';
  document.getElementById('priority').value        = history.priority || 3;
  document.getElementById('driver_name').value     = history.driver_name || '';
  document.getElementById('plate_no').value        = history.plate_no || '';
}

document.getElementById('historyForm').addEventListener('submit', async (e) => {
  e.preventDefault();
  const body = {
    order_no:       document.getElementById('order_no').value,
    customer_name:  document.getElementById('customer_name').value,
    address:        document.getElementById('address').value,
    region:         document.getElementById('region').value,
    scheduled_time: document.getElementById('scheduled_time').value,
    weight:         document.getElementById('weight').value || null,
    priority:       parseInt(document.getElementById('priority').value) || 3,
    driver_name:    document.getElementById('driver_name').value,
    plate_no:       document.getElementById('plate_no').value,
  };
  const url    = mode === 'new' ? '/api/history' : '/api/history/' + historyId;
  const method = mode === 'new' ? 'POST' : 'PUT';
  const res = await fetch(url, {method, headers:{'Content-Type':'application/json'}, body: JSON.stringify(body)});
  if (res.ok) location.href = 'history_manage.asp';
  else alert('儲存失敗，請確認資料後重試');
});
</script>
<!-- #include file="includes/footer.asp" -->
