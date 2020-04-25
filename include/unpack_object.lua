-- unpacks an object packed by pack_object. returns the unpacked object. input is an array of
-- five strings, with encoded triangle vertices, normal vertices, triangles (as vertex indices),
-- materials and layers, respectively.
-- uses hex_to_dec.lua

function unpack_object(input)

 local obj = {verts_tri = {}, verts_normal = {}, tris = {}, mats = {}, layers = {}}
 
 function unpack_verts(n, verts)
  for i = 1, #input[n] - 1, 12 do
   vert, vertstr = {}, sub(input[n], i, i + 11)
   for j=1, 9, 4 do
    coord_substr = sub(vertstr, j, j + 3)
    add(vert, tonum("0x"..sub(coord_substr, 1, 1).."."..sub(coord_substr, 2, 4)) - 8)
   end
   add(verts, vert)
  end
 end
 
 unpack_verts(1, obj.verts_tri)
 unpack_verts(2, obj.verts_normal)
 
 for i = 1, #input[4] do
  k, tri = i * 8 - 7, {}
  for j = k, k + 7, 2 do
   add(tri, hex_to_dec(input[3], j, 1))
  end
  add(obj.tris, tri)
  add(obj.mats, tonum(sub(input[4], i, i)))
  add(obj.layers,tonum(sub(input[5], i, i)))
 end

 return obj
 
end