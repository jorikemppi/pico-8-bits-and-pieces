-- draw a filled triangle with line(), using current draw state
-- input: a triangle as an array, like {{x1, y1}, {x2, y2}, {x3, y3}}
-- uses flat_trifill.lua

function trifill(v)

  for i2=1,3 do
   local j=i2
   while j>1 and v[j-1][2]>v[j][2] do
    v[j],v[j-1]=v[j-1],v[j]
    j-=1
   end 
  end
 
 x1, x2, x3, y1, y2, y3=v[1][1], v[2][1], v[3][1], v[1][2], v[2][2], v[3][2]
  
 x4 = x1 + ((y2 - y1) / (y3 - y1)) * (x3 - x1)
  
 flat_trifill(x1, y1, x2, y2, x4, 1)
 flat_trifill(x3, y3, x2, y2, x4, 0xffff) 

end