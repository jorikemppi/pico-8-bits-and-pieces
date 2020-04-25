-- returns a render queue with layer_amount layers.
-- usage: rq = initialize_render_queue(2)

function initialize_render_queue(layer_amount)

 rq = {}
 
 for i = 1, layer_amount do
  add(rq, {})
 end
 
 return rq
 
end