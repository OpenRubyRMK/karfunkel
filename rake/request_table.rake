# -*- coding: utf-8 -*-
#
# This file is part of OpenRubyRMK.
# 
# Copyright © 2011 OpenRubyRMK Team
# 
# OpenRubyRMK is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# OpenRubyRMK is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with OpenRubyRMK.  If not, see <http://www.gnu.org/licenses/>.

#The HTML around the table to make it a full HTML page.
#This is a format string, so don’t be surprised by
#some percent-ism.
HTML =<<HTML
<html>
  <head>
    <title>Karfunkel server requests</title>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <style type="text/css">
body {
  background-color: #CCCCCC;
  font-family: DejaVu Serif, Times, roman;
}
table{
  border: 1px solid black;
  border-collapse: collapse;
}
table td, th{
  border: 1px solid black;
}
tr.request-detail {
  background-color: gray;
  font-family: sans-serif;
}
tr.request {
  font-size: 150%%;
  background-color: #F65327;
  font-family: sans-serif;
}
tr.parameters-list {
  text-align: left;
  background-color: #DDDD00;
  font-family: sans-serif;
}
    </style>
  </head>
  <body>
    <table>
      %s
    </table>
  </body>
</html>
HTML

#Source file for the request documentation file.
SERVER_REQUESTS_SOURCE_FILE = ROOT_DIR + "server_requests.yml"
#Destination file for the requests documentation file.
SERVER_REQUESTS_FINAL_FILE  = DOC_DIR + "server_requests.html"

#Ensure the final file gets clobbered.
CLOBBER.include(SERVER_REQUESTS_FINAL_FILE.to_s)

#Generates a <td></td>-<td></td> pair for a parameter-description
#construct. Used by #parhsh.
def pars(par_name, par_desc)
  r = RedCloth.new(par_desc.to_s)
  r.lite_mode = true
  "<td><tt>" << par_name.to_s << "</tt></td><td>" << r.to_html << "</td>"
end

#Generates the table cells for parameters descriptions.
#Takes the "paramers" hash, the +name+ to place ontop of the
#parameter listing and an optional description to be displayed
#between the two.
def parhsh(hsh, name, desc = nil)
  html = ""
  html << "<tr class='parameters-list'><th colspan='4'>#{name}</th></tr>\n"
  html << element_desc(desc) if desc
  
  hsh.to_a.flatten.each_slice(4) do |parname, pardesc, parname2, pardesc2|
    html << "<tr>" << pars(parname, pardesc) << pars(parname2, pardesc2) << "</tr>\n"
  end
  html
end

#Generates the table row containing a table heading such
#as "Responses".
def table_heading(str)
  "<tr class='request-detail'><th colspan='4'>#{str}</th></tr>\n"
end

def request_heading(reqname)
  "<tr class='request'><th colspan='4'><a name=#{reqname}>#{reqname}</a></th></tr>\n"
end

#Generates the description for a single element, e.g. 
#the request description or a response’s description.
def element_desc(textile)
  r = RedCloth.new(textile.to_s)
  r.lite_mode = true
  "<tr class='desc'><td colspan='4'>#{r.to_html}</td></tr>\n"
end

def sorted_each_pair(hsh)
  hsh.keys.sort.each do |key|
    yield(key, hsh[key])
  end
end

#Actually documents the requests.
def document_requests
  rm SERVER_REQUESTS_FINAL_FILE if SERVER_REQUESTS_FINAL_FILE.file?
  
  table_content = ""
  request_hsh = YAML.load_file(SERVER_REQUESTS_SOURCE_FILE)
  
  sorted_each_pair(request_hsh) do |request, hsh|
    table_content << request_heading(request)
    table_content << element_desc(hsh["desc"])
    
    #Parameters
    table_content << table_heading("Main request")
    table_content << parhsh(hsh["parameters"], "Parameters")

    table_content << table_heading("Responses")
    sorted_each_pair(hsh["responses"]) do |respname, resphsh|
      table_content << parhsh(resphsh["parameters"], respname, resphsh["desc"])
    end

    if hsh["notifications"]
      table_content << table_heading("Notifications")
      sorted_each_pair(hsh["notifications"]) do |respname, notehsh|
        table_content << parhsh(notehsh["parameters"], respname, notehsh["desc"])
      end
    end
  end
  File.open(SERVER_REQUESTS_FINAL_FILE, "w"){|f| f.write(HTML % table_content)}
end
