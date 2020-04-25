-- packs an object into strings of hexadecimal digits. returns five strings
-- (triangle vertices, normals, triangles, materials and layers, respectively)

function pack_object(obj)

 str_verts_tri = ""
 
 for i in all(obj.verts_tri) do
  for j in all(i) do
   substr = tostr(j + 8, true)
   str = sub(substr, 6, 6)..sub(substr, 8, 10)
   str_verts_tri = str_verts_tri..str
  end
 end 
 
 str_verts_normal = ""
 for i in all(obj.verts_normal) do
  for j in all(i) do
   substr = tostr(j + 8, true)
   str = sub(substr, 6, 6)..sub(substr, 8, 10)
   str_verts_normal = str_verts_normal..str
  end
 end
 
 str_tris = ""
 
 for i in all(obj.tris) do
  for j in all(i) do
   str_tris = str_tris..sub(tostr(j,true), 5, 6)
  end
 end
 
 str_mats = ""
 
 for i in all(obj.mats) do
  str_mats = str_mats..i
 end
 
 str_layers = ""
 
 for i in all(obj.layers) do
  str_layers = str_layers..i
 end
 
 return str_verts_tri, str_verts_normal, str_tris, str_mats, str_layers

end