--scale(object, scale_amount): scales object.

function scale(object, scale_amount)
 for i in all(object.verts_tri) do
  i[1]*=scale_amount
  i[2]*=scale_amount
  i[3]*=scale_amount
 end
end