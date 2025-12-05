<%@ Page Language="C#" AutoEventWireup="true" %>
<!DOCTYPE html>
<html>
<head><title>Test Page</title></head>
<body>
    <h1>Test Page - No Code Behind</h1>
    <p>Current Time: <%= DateTime.Now.ToString() %></p>
    <p>Server: <%= System.Environment.MachineName %></p>
    <p>Framework: <%= System.Environment.Version.ToString() %></p>
</body>
</html>
