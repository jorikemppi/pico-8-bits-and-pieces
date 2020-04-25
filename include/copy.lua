-- copy(object): returns a copy of an object. mainly used to return an object to its original
-- state after a transformation. all the transformation functions modify the vertices directly,
-- which is token efficient as it does not require matrix multiplication, but it is destructive,
-- and needs a way to restore the original vertex data.

function copy(object)
 local cpy = {verts_normal = {}, verts_tri = {}}
 function vertcopy(copyverts, origverts)
  for i in all(origverts) do
   add(copyverts, {i[1], i[2], i[3]})
  end
 end
 vertcopy(cpy.verts_tri, object.verts_tri)
 vertcopy(cpy.verts_normal, object.verts_normal)
 
 cpy.tris, cpy.mats, cpy.layers = object.tris, object.mats, object.layers

 return cpy
end
----------------------------------------------