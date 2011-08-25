#Encoding: UTF-8

OpenRubyRMK::Karfunkel::SM::Request.define :Ping do
  
  execute do |client|
    #If Karfunkel gets a PING request, we just answer it as OK and
    #are done with it.
    answer client, :ok
  end
  
  process_response do |client, response|
    #Nothing is necessary here, because a client’s availability status
    #is set automatically if it sends a reponse. I just place the
    #method here, because without it we would get a NotImplementedError
    #exception.
  end
  
end