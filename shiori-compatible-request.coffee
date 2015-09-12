if require?
  ShioriJK = require 'shiorijk'
else
  ShioriJK = @ShioriJK

###
SHIORI/2.x互換変換
- GET : Sentence : OnCommunicate はGET Sentence SHIORI/2.3に変換され、ヘッダの位置が変更されます。
- GET : TEACH : OnTeach はTEACH SHIORI/2.4に変換され、ヘッダの位置が変更されます。
###
shiori_compatible_request = (method, version, id, headers={}) ->
  request = new ShioriJK.Message.Request()
  request.request_line.protocol = "SHIORI"
  request.request_line.version = version
  if version == '3.0'
    request.request_line.method = method[0]
    request.headers.header["ID"] = id
  else
    if method[1] == null
      throw new Error("event is not compatible to SHIORI 2.x") # through no SHIORI/2.x event
    method[1] ?= 'Sentence' # default SHIORI/2.2
    unless method[1] == 'TEACH'
      request.request_line.method = method[0] + ' ' + method[1]
    else
      request.request_line.method = method[1]
    if method[1] == 'Sentence' and id?
      if id == "OnCommunicate" # SHIORI/2.3b
        request.headers.header["Sender"] = headers["Reference0"]
        request.headers.header["Sentence"] = headers["Reference1"]
        request.headers.header["Age"] = headers.Age || "0"
        for key, value of headers
          if result = key.match(/^Reference(\d+)$/)
            request.headers.header["Reference"+(result[1]-2)] = ''+value
          else
            request.headers.header[key] = ''+value
        headers = null
      else # SHIORI/2.2
        headers["Event"] = id
    else if method[1] == 'String' and id? # SHIORI/2.5
      headers["ID"] = id
    else if method[1] == 'TEACH' # SHIORI/2.4
      request.headers.header["Word"] = headers["Reference0"]
      for key, value of headers
        if result = key.match(/^Reference(\d+)$/)
          request.headers.header["Reference"+(result[1]-1)] = ''+value
        else
          request.headers.header[key] = ''+value
      headers = null
    else if method[1] == 'OwnerGhostName' # SHIORI/2.0 NOTIFY
      request.headers.header["Ghost"] = headers["Reference0"]
      headers = null
    else if method[1] == 'OtherGhostName' # SHIORI/2.3 NOTIFY
      ghosts = []
      for key, value of headers
        if key.match(/^Reference\d+$/)
          ghosts.push ''+value
        else
          request.headers.header[key] = ''+value
      ghosts_headers = (ghosts.map (ghost) -> "GhostEx: #{ghost}\r\n").join("")
      request = request.request_line + "\r\n" + request.headers + ghosts_headers + "\r\n"
      headers = null
  if headers?
    for key, value of headers
      request.headers.header[key] = ''+value
  ""+request

if module?.exports?
  module.exports = shiori_compatible_request
else
  @shiori_compatible_request = shiori_compatible_request
