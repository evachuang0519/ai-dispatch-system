<%@ CodePage=65001 %>
<!-- #include file="includes/header.asp" -->
<!-- #include file="includes/db_conn.asp" -->
<%
Dim mode, historyId, historyJson, driversJson, vehiclesJson
mode      = Request.QueryString("mode")
historyId = Request.QueryString("id")
historyJson  = "null"
driversJson  = GetAPI("/api/drivers?active=true")
vehiclesJson = GetAPI("/api/vehicles?active=true")

If mode = "edit" And historyId <> "" Then
    historyJson = GetAPI("/api/history/" & historyId)
End If
%>
<div class="flex items-center justify-between mb-4">
  <h1 class="text-xl font-bold"><%If mode="new" Then%>新增歷史派單<%Else%>編輯歷史派單<%End If%></h1>
  <a href="history_manage.asp" class="px-4 py-2 rounded border hover:bg-gray-100 text-sm">取消</a>
</div>

<form id="historyForm" class="bg-white shadow rounded p-6 space-y-4 max-w-4xl">

  <h2 class="font-semibold text-blue-700 border-b pb-1">基本資料</h2>
  <div class="grid grid-cols-3 gap-4">
    <div>
      <label class="block text-sm font-medium mb-1">日期（民國）</label>
      <input id="order_date_roc" type="text" placeholder="1141121" class="w-full border rounded px-3 py-2">
    </div>
    <div>
      <label class="block text-sm font-medium mb-1">客戶</label>
      <select id="customer_type" class="w-full border rounded px-3 py-2">
        <option value="">請選擇</option>
        <option value="電話">電話</option>
        <option value="包月">包月</option>
      </select>
    </div>
    <div>
      <label class="block text-sm font-medium mb-1">個案名 <span class="text-red-500">*</span></label>
      <input id="customer_name" type="text" required class="w-full border rounded px-3 py-2">
    </div>
    <div>
      <label class="block text-sm font-medium mb-1">身分證字號</label>
      <input id="id_no" type="text" class="w-full border rounded px-3 py-2">
    </div>
    <div>
      <label class="block text-sm font-medium mb-1">連絡電話</label>
      <input id="contact_phone" type="text" class="w-full border rounded px-3 py-2">
    </div>
    <div>
      <label class="block text-sm font-medium mb-1">補助/自費</label>
      <select id="payment_type" class="w-full border rounded px-3 py-2">
        <option value="">請選擇</option>
        <option value="1">1. 補助</option>
        <option value="2">2. 自費</option>
      </select>
    </div>
    <div>
      <label class="block text-sm font-medium mb-1">性質</label>
      <select id="trip_type" class="w-full border rounded px-3 py-2">
        <option value="">請選擇</option>
        <option value="送">送</option>
        <option value="來">來</option>
        <option value="單">單</option>
      </select>
    </div>
    <div>
      <label class="block text-sm font-medium mb-1">客上</label>
      <input id="pickup_time" type="time" class="w-full border rounded px-3 py-2">
    </div>
    <div>
      <label class="block text-sm font-medium mb-1">客下</label>
      <input id="dropoff_time" type="time" class="w-full border rounded px-3 py-2">
    </div>
    <div>
      <label class="block text-sm font-medium mb-1">地區</label>
      <select id="region" class="w-full border rounded px-3 py-2">
        <option value="">請選擇</option>
        <option value="北區">北區</option>
        <option value="中區">中區</option>
        <option value="南區">南區</option>
        <option value="土城區">土城區</option>
        <option value="板橋區">板橋區</option>
        <option value="新莊區">新莊區</option>
        <option value="三重區">三重區</option>
      </select>
    </div>
    <div class="col-span-2">
      <label class="block text-sm font-medium mb-1">出發地</label>
      <input id="departure" type="text" class="w-full border rounded px-3 py-2">
    </div>
    <div class="col-span-3">
      <label class="block text-sm font-medium mb-1">目的地</label>
      <input id="destination" type="text" class="w-full border rounded px-3 py-2">
    </div>
  </div>

  <h2 class="font-semibold text-blue-700 border-b pb-1 pt-2">費用</h2>
  <div class="grid grid-cols-4 gap-4">
    <div>
      <label class="block text-sm font-medium mb-1">里程</label>
      <input id="mileage" type="number" step="0.001" min="0" class="w-full border rounded px-3 py-2">
    </div>
    <div>
      <label class="block text-sm font-medium mb-1">車資</label>
      <input id="fare" type="number" min="0" class="w-full border rounded px-3 py-2">
    </div>
    <div>
      <label class="block text-sm font-medium mb-1">陪同金額</label>
      <input id="companion_fee" type="number" min="0" class="w-full border rounded px-3 py-2">
    </div>
    <div>
      <label class="block text-sm font-medium mb-1">自付金額</label>
      <input id="self_pay" type="number" class="w-full border rounded px-3 py-2">
    </div>
    <div class="col-span-2">
      <label class="block text-sm font-medium mb-1">補助餘額</label>
      <input id="subsidy_balance" type="text" placeholder="例: 1000-200=800" class="w-full border rounded px-3 py-2">
    </div>
    <div>
      <label class="block text-sm font-medium mb-1">身分資格</label>
      <input id="qualification" type="text" placeholder="例: 低收入戶" class="w-full border rounded px-3 py-2">
    </div>
    <div>
      <label class="block text-sm font-medium mb-1">等級</label>
      <input id="grade" type="text" class="w-full border rounded px-3 py-2">
    </div>
  </div>

  <h2 class="font-semibold text-blue-700 border-b pb-1 pt-2">派單</h2>
  <div class="grid grid-cols-3 gap-4">
    <div>
      <label class="block text-sm font-medium mb-1">司機</label>
      <select id="driver_name" class="w-full border rounded px-3 py-2">
        <option value="">請選擇</option>
      </select>
    </div>
    <div>
      <label class="block text-sm font-medium mb-1">車號</label>
      <select id="plate_no" class="w-full border rounded px-3 py-2">
        <option value="">請選擇</option>
      </select>
    </div>
    <div>
      <label class="block text-sm font-medium mb-1">車型/配件</label>
      <input id="vehicle_accessories" type="text" placeholder="例: 一般" class="w-full border rounded px-3 py-2">
    </div>
  </div>

  <h2 class="font-semibold text-blue-700 border-b pb-1 pt-2">其他</h2>
  <div class="grid grid-cols-2 gap-4">
    <div>
      <label class="block text-sm font-medium mb-1">填單人</label>
      <input id="form_filler" type="text" class="w-full border rounded px-3 py-2">
    </div>
    <div>
      <label class="block text-sm font-medium mb-1">備註</label>
      <input id="note" type="text" class="w-full border rounded px-3 py-2">
    </div>
  </div>

  <div class="flex gap-3 pt-2">
    <button type="submit" class="bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700">儲存</button>
    <a href="history_manage.asp" class="px-6 py-2 rounded border hover:bg-gray-100">取消</a>
  </div>
</form>

<script>
const mode      = "<%=mode%>";
const historyId = "<%=historyId%>";
const rec       = <%=historyJson%>;
const drivers   = <%=driversJson%> || [];
const vehicles  = <%=vehiclesJson%> || [];

drivers.forEach(d  => document.getElementById('driver_name').appendChild(new Option(d.name, d.name)));
vehicles.forEach(v => document.getElementById('plate_no').appendChild(new Option(v.plate_no, v.plate_no)));

function rocToIso(roc) {
  const s = String(roc).replace(/\D/g, '');
  if (s.length === 7) {
    const y = parseInt(s.slice(0,3)) + 1911;
    return `${y}-${s.slice(3,5)}-${s.slice(5,7)}`;
  }
  return roc;
}
function isoToRoc(iso) {
  if (!iso) return '';
  const d = new Date(iso);
  const y = d.getFullYear() - 1911;
  const m = String(d.getMonth()+1).padStart(2,'0');
  const day = String(d.getDate()).padStart(2,'0');
  return `${y}${m}${day}`;
}

if (rec) {
  document.getElementById('order_date_roc').value    = rec.order_date ? isoToRoc(rec.order_date) : '';
  document.getElementById('customer_type').value     = rec.customer_type || '';
  document.getElementById('customer_name').value     = rec.customer_name || '';
  document.getElementById('id_no').value             = rec.id_no || '';
  document.getElementById('contact_phone').value     = rec.contact_phone || '';
  document.getElementById('payment_type').value      = rec.payment_type || '';
  document.getElementById('trip_type').value         = rec.trip_type || '';
  document.getElementById('pickup_time').value       = (rec.pickup_time||'').slice(0,5);
  document.getElementById('dropoff_time').value      = (rec.dropoff_time||'').slice(0,5);
  document.getElementById('region').value            = rec.region || '';
  document.getElementById('departure').value         = rec.departure || rec.address || '';
  document.getElementById('destination').value       = rec.destination || '';
  document.getElementById('mileage').value           = rec.mileage || '';
  document.getElementById('fare').value              = rec.fare || '';
  document.getElementById('companion_fee').value     = rec.companion_fee || '';
  document.getElementById('self_pay').value          = rec.self_pay || '';
  document.getElementById('subsidy_balance').value   = rec.subsidy_balance || '';
  document.getElementById('qualification').value     = rec.qualification || '';
  document.getElementById('grade').value             = rec.grade || '';
  document.getElementById('driver_name').value       = rec.driver_name || '';
  document.getElementById('plate_no').value          = rec.plate_no || '';
  document.getElementById('vehicle_accessories').value = rec.vehicle_accessories || '';
  document.getElementById('form_filler').value       = rec.form_filler || '';
  document.getElementById('note').value              = rec.note || '';
}

document.getElementById('historyForm').addEventListener('submit', async (e) => {
  e.preventDefault();
  const rocDate   = document.getElementById('order_date_roc').value.trim();
  const isoDate   = rocDate ? rocToIso(rocDate) : null;
  const pickupT   = document.getElementById('pickup_time').value;
  const scheduledTime = isoDate && pickupT ? `${isoDate}T${pickupT}:00` : (isoDate ? `${isoDate}T00:00:00` : null);

  const body = {
    order_date:           isoDate,
    customer_type:        document.getElementById('customer_type').value,
    customer_name:        document.getElementById('customer_name').value,
    id_no:                document.getElementById('id_no').value,
    contact_phone:        document.getElementById('contact_phone').value,
    payment_type:         parseInt(document.getElementById('payment_type').value) || null,
    trip_type:            document.getElementById('trip_type').value,
    pickup_time:          pickupT || null,
    dropoff_time:         document.getElementById('dropoff_time').value || null,
    region:               document.getElementById('region').value,
    departure:            document.getElementById('departure').value,
    destination:          document.getElementById('destination').value,
    mileage:              parseFloat(document.getElementById('mileage').value) || null,
    fare:                 parseFloat(document.getElementById('fare').value) || null,
    companion_fee:        parseFloat(document.getElementById('companion_fee').value) || null,
    self_pay:             parseFloat(document.getElementById('self_pay').value) || null,
    subsidy_balance:      document.getElementById('subsidy_balance').value,
    qualification:        document.getElementById('qualification').value,
    grade:                document.getElementById('grade').value,
    driver_name:          document.getElementById('driver_name').value,
    plate_no:             document.getElementById('plate_no').value,
    vehicle_accessories:  document.getElementById('vehicle_accessories').value,
    form_filler:          document.getElementById('form_filler').value,
    note:                 document.getElementById('note').value,
    scheduled_time:       scheduledTime,
  };

  const url    = mode === 'new' ? API_BASE + '/api/history' : API_BASE + '/api/history/' + historyId;
  const method = mode === 'new' ? 'POST' : 'PUT';
  const res = await fetch(url, {method, headers:{'Content-Type':'application/json'}, body: JSON.stringify(body)});
  if (res.ok) location.href = 'history_manage.asp';
  else alert('儲存失敗，請確認資料後重試');
});
</script>
<!-- #include file="includes/footer.asp" -->
