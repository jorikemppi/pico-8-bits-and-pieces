-- renders the render queue generated with send_to_queue
-- uses trifill.lua

function render_queue()

 for layer in all(rq) do
  for i = 1, #layer do
  local j = i
   while j>1 and layer[j - 1][7] > layer[j][7] do
    layer[j], layer[j - 1] = layer[j - 1], layer[j]
    j -= 1
   end 
  end
  
  for i in all(layer) do   
   color(i[5].curve_patterns[i[6]])
   trifill(i)
  end
 end
 
 fillp()
 
end