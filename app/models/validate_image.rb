require 'rubygems'
require 'RMagick'

class ValidateImage  < ActiveRecord::Base
  include Magick
  attr_reader :code, :code_image
  Jiggle = 15
  Wobble = 15
  def initialize(var)    
    chars = ('a'..'z').to_a - ['a','e','i','o','u']
    code_array=[]

    if var.is_a?(Integer)
      1.upto(var) {code_array << chars[rand(chars.length)]}
      len = var
    elsif var.is_a?(String)
       var.each_char {|c| code_array << c}
       len = var.size
    end
        

    #create granite style background
    #optional styles: 
    #gradient, gradient. e.g. "gradient:red-blue"
    #granite, granite.  gradient. e.g. “granite:”
    #logo logo-like image. e.g. “logo:”
    #netscape e.g. “netscape:”
    #null e.g. “null:”
    #rose e.g. “rose:”
    #xc set a background color. etc. ”xc:green”
    
    style = Magick::ImageList.new('xc:#EDF7E7')
    #define canvas
    canvas = Magick::ImageList.new
    # add style to canvas
    canvas.new_image(32*len, 50, Magick::TextureFill.new(style))
    #define font
    text = Magick::Draw.new
    text.font_family = 'times'
    text.pointsize = 40
    cur = 10
    code_array.each{|c|
      rand(10) > 5 ? rot=rand(Wobble):rot= -rand(Wobble)
      rand(10) > 5 ? weight = NormalWeight : weight = BoldWeight
      # add text object to canvas
      text.annotate(canvas,0,0,cur,30+rand(Jiggle),c){
        #rotate angle
        self.rotation=rot 
        #text size
        self.font_weight = weight 
        #text color
        self.fill = 'green'
      }
      cur += 30
    }
    #create Captcha text
    @code = code_array.to_s
    #create Captcha image
    @code_image = canvas.to_blob{
      self.format="jpeg"
    }
  end
end