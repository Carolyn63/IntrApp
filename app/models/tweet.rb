class Tweet < ActiveResource::Base
self.site = "http://twitter.com/"
self.element_name = 'status'
self.timeout = 5

self.user = "rajavenkates"
self.password = "saranroshi"
end