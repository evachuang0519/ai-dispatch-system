<%
Response.Charset = "UTF-8"
Response.CodePage = 65001
%><!DOCTYPE html>
<html lang="zh-TW">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>AI 自動派單系統</title>
<script src="https://cdn.tailwindcss.com"></script>
<script>const API_BASE = 'http://localhost:8000';</script>
</head>
<body class="bg-gray-50 text-gray-800">
<nav class="bg-blue-700 text-white px-6 py-3 flex items-center gap-6 shadow">
  <span class="font-bold text-lg">AI 派單系統</span>
  <a href="drivers.asp" class="hover:underline">司機管理</a>
  <a href="vehicles.asp" class="hover:underline">車輛管理</a>
  <a href="vehicle_types.asp" class="hover:underline">車型設定</a>
  <a href="history_manage.asp" class="hover:underline">歷史派單</a>
  <a href="upload.asp" class="hover:underline">上傳訂單</a>
  <a href="dispatch.asp" class="hover:underline">AI 派單</a>
  <a href="learning_log.asp" class="hover:underline">學習記錄</a>
  <a href="report.asp" class="hover:underline">派單報表</a>
</nav>
<div class="p-6">
