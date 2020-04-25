pico-8 cartridge // http://www.pico-8.com
version 21
__lua__

-- converts an object in the wavefront OBJ format into a format understood by the rendering system

-- currently assumes the object is triangulated, so you need to triangulate it first

-- separate objects in the file are assigned their own material and layer indices
-- the layers are used to force a drawing order in case the painter's algorithm fails

-- discards vertex normals as those are not useful for flat shading, generates face normals instead

-- exports object and material data, and a code template with a basic rendering loop

-- decodes a string into a table
-- "1_2_3|" results in a one-dimensional table
-- "1_2_3|4_5_6|" results in a two-dimensional table, where table[2] = {4, 5, 6}

#include include/parse_table.lua
#include include/dot3d_rotate.lua
#include include/flatten_point.lua
#include include/round.lua
#include include/generate_gradient.lua

#include include/trifill_editor.lua
#include include/flat_trifill.lua

#include include/copy.lua
#include include/rotate.lua
#include include/translate.lua
#include include/scale.lua
#include include/reflect.lua

#include include/initialize_render_queue.lua

#include include/send_to_queue_editor.lua
#include include/unpack_object.lua

#include include/hex_to_dec.lua

#include include/render_queue_editor.lua

#include include/pack_object.lua

#include include/shades.lua

highlight=1

function generate_normals()

 obj.verts_normal = {}
 
 for i in all(obj.tris) do

  tri_verts = {}
  
  for j in all(i) do
   add(tri_verts,obj.verts_tri[j])
  end
  
  d1={
   tri_verts[2][1] - tri_verts[1][1],
   tri_verts[2][2] - tri_verts[1][2],
   tri_verts[2][3] - tri_verts[1][3]
  }
  d2={
   tri_verts[3][1] -tri_verts[2][1],
   tri_verts[3][2] -tri_verts[2][2],
   tri_verts[3][3]  -tri_verts[2][3]
  }
  cross={
   d1[2] *d2[3] - d1 [3] * d2[2],
   d1[3] *d2[1] - d1 [1] * d2[3],
   d1[1] *d2[2] - d1 [2] * d2[1]
  }
  dist = sqrt(cross[1] ^ 2 + cross[2] ^ 2 + cross[3] ^ 2)
  normal={
   cross[1] / dist,
   cross[2] / dist,
   cross[3] / dist
  }
  
  found = false
  for j = 1,#obj.verts_normal do
   if obj.verts_normal[j][1] == normal[1] and obj.verts_normal[j][2] == normal[2] and obj.verts_normal[j][3] == normal[3] then
    i[4] = j
    found = true
    break
   end
  end
  
  if found == false then
   add(obj.verts_normal, normal)
   i[4] = #obj.verts_normal
  end
  
 end
 
end

function _init()

 import_selector = 1
 
 mode = 1
 select_mode = 1 

 axis_labels = {"x", "y", "z"}
 
 trans = {0, 0, -9}
 trans_axis = 2
 
 rot_mode = 1
 rot_mode_labels = {"smooth", "coarse"}
 rot_axis = 1
 
 scale_amount = 1
 
 reflect_axis = 1
 
 material_selector = 1
 
 step_selector = 1
 
 bake_selector = 1

 obj = {verts_tri = {}, verts_normal = {}, tris = {}, mats = {}, layers = {}}
 read = {verts = {}, tris = {}}
 input = ""
 readline = sub(stat(4), 1, 25)
 refresh = true
 
 repeat
 
  if btnp(2) then
   import_selector -= 1
   refresh = true
  end
  
  if btnp(3) then
   import_selector += 1
   refresh = true
  end
 
  if refresh == true then
  
   if (import_selector < 1) import_selector = 3
   if (import_selector > 3) import_selector = 1
   
   cls()
   
   pal(15, 7, 1)
   pal(14, 137, 1)
   
   color(15)
   
   print("paste an object", 34, 30)
   print("press \142 to import", 28, 36)
   
   print("current input:", 37, 48)
   
   print(readline, 14, 56)
   rect(12, 54, 114, 62)
   
   if (import_selector == 1) color(14)
   print("import wavefront .obj", 22, 72)
   rect(20, 70, 106, 78)
   color(15)
   
   if (import_selector == 2) color(14)
   print("import internal format", 20, 82)
   rect(18, 80, 108, 88)
   color(15)
   
   if (import_selector == 3) color(14)
   print("create cube", 42, 92)
   rect(40, 90, 86, 98)
   color(15)
   
   refresh = false
   
  end
  
  new_readline = sub(stat(4), 1, 25)
  flip()
  
  if new_readline != readline then
   readline = new_readline
   refresh = true
  end
  
 until btnp(4)
 
 input = stat(4)
 
 material_parameter = {}
 
 if import_selector == 1 then
 
  i = 0  
  l = 0
  
  while i <= #input do
  
   i += 1  
   linestart = ""
   
   if sub(input, i, i) == "\n" then
    linestart = sub(input, i + 1, i + 2)
   end
   
   if linestart == "o " then
    l += 1
   end
   
   if linestart == "v " then
   
    i += 3
    repeat
     readline = readline..sub(input, i, i)
     i += 1   
    until sub(input, i, i)=="\n"
    i -= 1
    newvert = {}
    newcoord = ""
    j = 1
    while j <= #readline do
     char = sub(readline, j, j)
     if char != " " then
      newcoord = newcoord..char
     end
     j += 1
     if char == " " or j > #readline then
      add(newvert, tonum(newcoord))
      newcoord = ""
     end
    end
    readline = ""
    add(read.verts, newvert)
   
   end
  
   if linestart=="f " then
    
    i += 3
    newfacevert_read = ""
    repeat
     readline = readline..sub(input, i, i)
     i += 1   
    until sub(input, i, i) == "\n"
    i -= 1
    
    splitline = {""}
    for j = 1, #readline do
     char = sub(readline, j, j)
    if char != " " then
     splitline[#splitline] = splitline[#splitline]..char
    else
     add(splitline, "")
    end
   
   end
   
   newtri={}
   
   for k in all(splitline) do
    splitface = {""}
    for l=1,#k do
     char = sub(k, l, l)
     if tonum(char) != nil then
      splitface[#splitface] = splitface[#splitface]..char
     else
      add(splitface, "")
     end
    end
    add(newtri, read.verts[tonum(splitface[1])])
   end
   
   
   add(read.tris, newtri)
   add(obj.mats, l)
   add(obj.layers, l)
   
   readline = ""
      
   end
   
  end

  for tri in all(read.tris) do
  
   newtri = {}
   
   for vert in all(tri) do
   
    found = false
    if #obj.verts_tri > 0 then
     for j = 1, #obj.verts_tri do
      if obj.verts_tri[j][1] == vert[1] and obj.verts_tri[j][2] == vert[2] and obj.verts_tri[j][3] == vert[3] then
       add(newtri, j)
       found = true
       break
      end
     end
    end
    
    if found == false then
     add(obj.verts_tri, vert)
     add(newtri, #obj.verts_tri)
    end
    
   end
   
   add(obj.tris, newtri)
  
  end

  generate_normals()
  
  for mat in all(obj.mats) do
   mat_amount = max(mat_amount, mat)
  end
 
  for i=1, mat_amount do 
   add_default_material()  
  end
  
 end
 
 if import_selector == 2 then
 
  cls()
 
  i = 1
  readmode = 1
  object_string = {"", "", "", "", ""}
  object_read_index = 0
  material_string = ""
  material_elements = 0
  
  while i<=#input do
  
   char = sub(input, i, i)
   
   if readmode == 1 then
   
    if char == "!" then
	 object_read_index += 1
	 if (object_read_index > 5) readmode = 2
	else
	 object_string[object_read_index] = object_string[object_read_index]..char
	end	 
   
   elseif readmode == 2 then

    material_string = material_string..char
	
	if (char == "|") material_elements += 1
	
	if material_elements == 4 then
	
	 new_material = parse_table(material_string)
	 
	 add(material_parameter, {
                           diffuse = new_material[1][1],
                           ambient = new_material[2][1],
                           curve_steps = {},
                           curve_colors = {}
                          })
	 
	 for i2 = 1, #new_material[3] do
	  material_parameter[#material_parameter].curve_steps[i2] = new_material[3][i2]
	  material_parameter[#material_parameter].curve_colors[i2] = new_material[4][i2]
	 end
	 
	 material_elements = 0
	 material_string = ""
	 
	end
	
   end						  
   
   i += 1
  
  end

  obj = unpack_object(object_string)
  
 end
 
 if import_selector == 3 then
 
  obj.verts_tri = {{-1, 1, 1},
                   {-1, 1, -1},
				   {1, 1, -1},
				   {1, 1, 1},
				   {-1, -1, 1},
				   {1, -1, 1},
				   {1, -1, -1},
				   {-1, -1, -1}}
			  
  obj.tris = {{3, 2, 1},
              {1, 4, 3},
			  {7, 8, 2},
			  {2, 3, 7},
			  {6, 5, 8},
			  {8, 7, 6},
			  {4, 1, 5},
			  {5, 6, 4},
			  {7, 3, 4},
			  {4, 6, 7},
			  {1, 2, 8},
			  {8, 5, 1}}
  
  obj.mats = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
  obj.layers = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
  
  generate_normals()
  
  add_default_material()
 
 end
 
 reset_obj = copy(obj)
 


 pal(0,129)
 pal()
 
 f=0
    
 generate_materials()
 
end

function add_default_material()

  add(material_parameter, {
                           diffuse = 128,
                           ambient = 32,
                           curve_steps = {0, 91, 105},
                           curve_colors = {0, 5, 7}
                          })
						  
end

function generate_materials()

 cls()
 
 material = {}
 gradient_start = 0
 
 for parameter in all(material_parameter) do
  
  add(material, {
                 diffuse = parameter.diffuse,
                 ambient = parameter.ambient,
                 curve_patterns = generate_gradient(parameter.curve_steps, gradient_start),
                 palette_index = gradient_start
                })
  
  gradient_start += #parameter.curve_steps
 
 end
  

end

function _update60()
 f+=1
end

function _draw()

 cls(13)
 
 i = 0
 for parameter in all(material_parameter) do
  for curve_color in all(parameter.curve_colors) do
   pal(i, curve_color, 1)
   i += 1
  end
 end
 
 pal(13, 0, 1)
 pal(15, 7, 1)
 pal(14, 137, 1)
 
 layers = 0
 for layer in all(obj.layers) do
  layers = max(layer, layers)
 end
 
 initialize_render_queue(layers)
 
 newobj = copy(obj)

 scale(newobj, scale_amount)
 translate(newobj, trans[1], trans[2], trans[3])  

 send_to_queue(newobj)
 render_queue()
 
 color(15)

 color(11)
 pset(64, 64)
 circ(64, 64, 8)

 if stat(34)==1 then find_face=true end
 
 color(14)
 
 if mode == 1 then
 
  modenames = {"material painter", "layer painter", "translate", "rotate", "scale", "reflect", "material editor"}
  mode_indices = {2, 3, 4, 5, 6, 12, 7}
  
  if (btnp(0)) select_mode -= 1
  if (btnp(1)) select_mode += 1
  
  if (select_mode < 1) select_mode = 7
  if (select_mode > 7) select_mode = 1
  
  if btnp(3) then
  
   obj.tris = {}
   obj.verts_tri = {}
   obj.verts_normal = {}
   
   function objreset(defaults, target) 
	for elem in all(defaults) do
	 new_elem = {}
	 for i in all(elem) do
	  add(new_elem, i)
	 end
	 add(target, new_elem)
	end
   end
   
   objreset(reset_obj.tris, obj.tris)
   objreset(reset_obj.verts_tri, obj.verts_tri)
   objreset(reset_obj.verts_normal, obj.verts_normal)
   
  end  
  
  if (btnp(4)) mode = mode_indices[select_mode]
  
  if (btnp(5)) mode = 99
  
  print("mode selector", 0, 0)
  print("\139/\145: cycle through modes", 0, 6)
  print("   \142: "..modenames[select_mode], 0, 12)
  print("   \151: send object to clipboard", 0, 18)
  print("   \131: reset transformations", 0, 24)
  print("       (resets rotate/reflect, ", 0, 30)
  print("        keeps layers/materials)", 0, 36)

 elseif mode == 2 then
 
  if (btnp(0)) highlight -= 1
  if (btnp(1)) highlight += 1
  
  if (highlight < 1) highlight = #obj.tris
  if (highlight > #obj.tris) highlight = 1
  
  if (btnp(2)) obj.mats[highlight] += 1
  if (btnp(3)) obj.mats[highlight] -= 1
  
  if (obj.mats[highlight] > #material) obj.mats[highlight] = 1
  if (obj.mats[highlight] < 1) obj.mats[highlight] = #material
 
  if (btnp(5)) mode = 1
  
  print("material painter", 0, 0)
  print("\139/\145: cycle through tris", 0, 6)
  print("\148/\131: change material", 0, 12)
  print("   \151: mode selector", 0, 18)
  
  print("      tri: "..highlight, 0, 30)
  print(" material: "..obj.mats[highlight], 0, 36)
 
 elseif mode == 3 then
 
  if (btnp(0)) highlight -= 1
  if (btnp(1)) highlight += 1
  
  if (highlight < 1) highlight = #obj.tris
  if (highlight > #obj.tris) highlight = 1
  
  if (btnp(2)) obj.layers[highlight] += 1
  if (btnp(3)) obj.layers[highlight] -= 1
  
  if (btnp(5)) mode = 1
  
  print("layer painter", 0, 0)
  print("\139/\145: cycle through tris", 0, 6)
  print("\148/\131: change layer", 0, 12)
  print("   \151: mode selector", 0, 18)
  
  print("      tri: "..highlight, 0, 30)
  print("    layer: "..obj.layers[highlight], 0, 36)
 
 elseif mode == 4 then
 
  if btnp(4) then
   if trans_axis == 2 then
    trans_axis = 3
   else
    trans_axis = 2
   end
  end
  
  if (btn(0)) trans[1] -= 0.1
  if (btn(1)) trans[1] += 0.1
  
  if (btn(2)) trans[trans_axis] -= 0.1
  if (btn(3)) trans[trans_axis] += 0.1
 
  if (btnp(5)) mode = 1
  
  print("translate object", 0, 0)
  print("   \142: swap axis for \148/\131", 0, 6)
  print("\139/\145: translate along x", 0, 12)
  print("\148/\131: translate along "..axis_labels[trans_axis], 0, 18)
  print("   \151: mode selector", 0, 24)
 
 elseif mode == 5 then
 
  if btnp(4) then
   if rot_mode == 1 then
    rot_mode = 2
   else
    rot_mode = 1
   end
  end
  
  if (btnp(0)) rot_axis -= 1
  if (btnp(1)) rot_axis += 1
  
  if (rot_axis < 1) rot_axis = 3
  if (rot_axis > 3) rot_axis = 1
  
  if rot_mode == 1 then
   if (btn(2)) rotate(obj, -0.01, axis_labels[rot_axis])
   if (btn(3)) rotate(obj, 0.01, axis_labels[rot_axis])
  end
  
  if rot_mode == 2 then
   if (btnp(2)) rotate(obj, -0.05, axis_labels[rot_axis])
   if (btnp(3)) rotate(obj, 0.05, axis_labels[rot_axis])
  end
 
  if (btnp(5)) mode = 1
  
  print("rotate object", 0, 0)
  print("\139/\145: select axis", 0, 6)
  print("\148/\131: rotate along "..axis_labels[rot_axis], 0, 12)
  print("   \142: mode: "..rot_mode_labels[rot_mode], 0, 18)
  print("   \151: mode selector", 0, 24)

 elseif mode == 6 then
 
  if (btn(2)) scale_amount *= 1.05
  if (btn(3)) scale_amount *= 0.95
 
  if (btnp(5)) mode = 1
  
  print("scale object", 0, 0)
  print("\148/\131: scale object", 0, 6)
  print("   \151: mode selector", 0, 12)
  
 elseif mode == 12 then
 
  if (btnp(0)) reflect_axis -= 1
  if (btnp(1)) reflect_axis += 1
  
  if (rot_axis < 1) reflect_axis = 3
  if (rot_axis > 3) reflect_axis = 1
  
  if (btnp(4)) reflect(obj, reflect_axis)
 
  if (btnp(5)) mode = 1
  
  print("rotate object", 0, 0)
  print("\139/\145: select axis", 0, 6)
  print("   \142: reflect along "..axis_labels[reflect_axis], 0, 12)
  print("   \151: mode selector", 0, 18)
 
 elseif mode == 7 then
 
  if (btnp(0)) material_selector -= 1
  if (btnp(1)) material_selector += 1
  
  if (material_selector < 1) material_selector = #material
  if (material_selector > #material) material_selector = 1
  
  if (btnp(2)) then
  
   add_default_parameter()
   
   generate_materials()
   
  end
  
  if (btnp(3)) and #material_parameter > 1 then
  
   new_parameters = {}
   
   for i = 1, #material_parameter do
    
	if i != material_selector then
	
	 add(new_parameters, {})	 
	 new_parameters[#new_parameters].diffuse = material_parameter[i].diffuse
	 new_parameters[#new_parameters].ambient = material_parameter[i].ambient
	 new_parameters[#new_parameters].curve_steps = {}
	 new_parameters[#new_parameters].curve_colors = {}
	 
	 for i2 = 1, #material_parameter[i].curve_steps do
	  add(new_parameters[#new_parameters].curve_steps, material_parameter[i].curve_steps[i2])
	  add(new_parameters[#new_parameters].curve_colors, material_parameter[i].curve_colors[i2])
	 end
	
	end
	
   end
   
   material_parameter = {}
   
   for i = 1, #new_parameters do
   
    add(material_parameter, {})	 
	material_parameter[#material_parameter].diffuse = new_parameters[i].diffuse
	material_parameter[#material_parameter].ambient = new_parameters[i].ambient
	material_parameter[#material_parameter].curve_steps = {}
	material_parameter[#material_parameter].curve_colors = {}
	 
	for i2 = 1, #new_parameters[i].curve_steps do
	 add(material_parameter[#material_parameter].curve_steps, new_parameters[i].curve_steps[i2])
	 add(material_parameter[#material_parameter].curve_colors, new_parameters[i].curve_colors[i2])
	end
	
   end
   
   for i = 1, #obj.mats do
    if obj.mats[i] >= material_selector and obj.mats[i] > 1 then obj.mats[i] -= 1 end
   end
   
   material_selector = min(material_selector, #material_parameter)
   
   generate_materials()
   
  end
  
  
  if (btnp(4)) mode = 8 
  if (btnp(5)) mode = 1
  
  print("material editor", 0, 0)
  print("\139/\145: select material", 0, 6)
  print("   \148: add material", 0, 12)
  print("   \131: delete material", 0, 18)
  print("   \142: edit material", 0, 24)
  print("   \151: mode selector", 0, 30)
  
  --if #material_parameter == 1 then
   line(11,20,87,20)
   
   print("delete disabled", 0, 42)
   print("must have at least one material", 0, 48)
  
  --end
  
  for i = 1, #material do
  
   --color(14)
  
   xloc = i * 10 - 9
   
   for y = 0, 63 do
    line(xloc, 57 + y, xloc + 8, 57 + y, material[i].curve_patterns[1 + y * 2])
   end
   
   color(14)
   
   if i == material_selector then
    color(15)   
    rect(xloc, 57, xloc + 8, 120)
   end
   
   print(i, xloc + 3, 122)

  end
 
 elseif mode == 8 then
 
  if (btnp(2)) step_selector -= 1
  if (btnp(3)) step_selector += 1
  
  if (step_selector < 1) step_selector = #material_parameter[material_selector].curve_steps
  if (step_selector > #material_parameter[material_selector].curve_steps) step_selector = 1
  
  if (btnp(0)) mode = 11
  if (btnp(4)) mode = 9
  if (btnp(5)) mode = 7
  
  ui_material_editor_draw_large_gradient()
 
  color(14)
  print("material editor", 17, 0)
  print("gradient mode", 17, 6)
  print("\148/\131: select step", 17, 12)
  print("   \142: lock step for editing", 17, 18)
  print("   \139: lighting mode", 17, 24)
  print("   \151: material selector", 17, 30)
 
 elseif mode == 9 then
 
  gradient_changed = false
 
  step_position = material_parameter[material_selector].curve_steps[step_selector]
  
  if step_selector == 1 then
   limit_min = 1
  else
   limit_min = material_parameter[material_selector].curve_steps[step_selector - 1] + 1
  end
  
  if step_selector == #material_parameter[material_selector].curve_steps then
   limit_max = 128
  else
   limit_max = material_parameter[material_selector].curve_steps[step_selector + 1] - 1
  end
  
  if btn(2) then
   step_position -= 1
   gradient_changed = true
  end
  
  if btn(3) then
   step_position += 1
   gradient_changed = true
  end
  
  step_position = mid(limit_min, limit_max, step_position)
  
  step_color = material_parameter[material_selector].curve_colors[step_selector]
  
  if btnp(0) then
   step_color -= 1
   if step_color > 15 and step_color < 128 then step_color = 15 end
   if step_color < 0 then step_color = 143 end
   gradient_changed = true
  end
  
  if btnp(1) then
   step_color += 1
   if step_color > 15 and step_color < 128 then step_color = 128 end
   if step_color > 143 then step_color = 0 end
   gradient_changed = true
  end

  if gradient_changed == true then
   material_parameter[material_selector].curve_colors[step_selector] = step_color
   material_parameter[material_selector].curve_steps[step_selector] = step_position
   generate_materials()
  end

  if (btnp(4)) mode = 10
  if (btnp(5)) mode = 8  
  
  ui_material_editor_draw_large_gradient()
 
  color(14)
  print("material editor", 17, 0)
  print("gradient mode", 17, 6)
  print("\148/\131: move step", 17, 12)
  print("\139/\145: change color", 17, 18)
  print("   \142: add/delete step", 17, 24)
  print("   \151: unlock step", 17, 30)
 
 elseif mode == 10 then
 
  if btnp(4) then
   newsteps, newcols = {}, {}   
   
   for i = 1, #material_parameter[material_selector].curve_steps do
   
    add(newsteps, material_parameter[material_selector].curve_steps[i])
    add(newcols, material_parameter[material_selector].curve_colors[i])
    
    if i == step_selector then
    
     if step_selector == #material_parameter[material_selector].curve_steps then
      nextstep_location = 128
     else
      nextstep_location = material_parameter[material_selector].curve_steps[i+1]
     end
    
     newstep_location = flr((material_parameter[material_selector].curve_steps[i] + nextstep_location) / 2)
     
     add(newsteps, newstep_location)
     add(newcols, material_parameter[material_selector].curve_colors[i])
    
    end

   end
   
   material_parameter[material_selector].curve_steps = {}
   material_parameter[material_selector].curve_colors = {}
   
   for i = 1, #newsteps do
    add(material_parameter[material_selector].curve_steps, newsteps[i])
    add(material_parameter[material_selector].curve_colors, newcols[i])
   end
   
   generate_materials()
   
   mode = 9
  
  end
 
  if btnp(5) and #material_parameter[material_selector].curve_steps > 2 then
   newsteps, newcols = {}, {}   
   
   for i = 1, #material_parameter[material_selector].curve_steps do
    if i != step_selector then
     add(newsteps, material_parameter[material_selector].curve_steps[i])
     add(newcols, material_parameter[material_selector].curve_colors[i])
    end
   end
   
   material_parameter[material_selector].curve_steps = {}
   material_parameter[material_selector].curve_colors = {}
   
   for i = 1, #newsteps do
    add(material_parameter[material_selector].curve_steps, newsteps[i])
    add(material_parameter[material_selector].curve_colors, newcols[i])
   end
   
   generate_materials()
   
   mode = 9
  
  end   
    
  ui_material_editor_draw_large_gradient()
  
  color(14)
  
  print("material editor", 17, 0)
  print("gradient mode", 17, 6)
  print("   \142: add step", 17, 12)
  print("   \151: delete step", 17, 18)
  print("   \139: cancel", 17, 24)
  
  if #material_parameter[material_selector].curve_steps < 3 then
   line(28, 20, 88, 20)
   print("delete disabled", 17, 36)
   print("must have at least 2 colors", 17, 42)
  end
 
 elseif mode == 11 then
 
  lighting_changed = false
  
  if btn(0) then
   material_parameter[material_selector].ambient -= 1
   lighting_changed = true
  end
  
  if btn(1) then
   material_parameter[material_selector].ambient += 1
   lighting_changed = true
  end
  
  if btn(2) then
   material_parameter[material_selector].diffuse -= 1
   lighting_changed = true
  end
  
  if btn(3) then
   material_parameter[material_selector].diffuse += 1
   lighting_changed = true
  end
  
  if lighting_changed == true then
   generate_materials()
  end
  
  if (btnp(4)) mode = 8
  if (btnp(5)) mode = 7
 
  ui_material_editor_draw_large_gradient()
  
  color(14)
  
  print("material editor", 17, 0)
  print("lighting mode", 17, 6)
  print("\139/\145: ambient ("..material_parameter[material_selector].ambient..")", 17, 12)
  print("\148/\131: diffuse ("..material_parameter[material_selector].diffuse..")", 17, 18)
  print("   \142: gradient mode", 17, 24)
  print("   \151: material selector", 17, 30)
  
 elseif mode == 99 then
  
  if btnp(0) or btnp(1) then
   if bake_selector == 1 then
    bake_selector = 2
   else
    bake_selector = 1
   end
  end
  
  if btnp(4) then
   export_object()
   mode = 1
  end
  
  print("bake x/y translation?", 22, 24)
  
  print("yes  no", 50, 36)
  
  if (bake_selector == 1) rect(48, 34, 62, 42)
  if (bake_selector == 2) rect(68, 34, 78, 42)
  
  print("\142: export object", 30, 90)
  
 end
 
end

function export_object()
 
 scale(obj, scale_amount)
 
 if (bake_selector == 1) translate(obj, trans[1], trans[2], 0) 
 
 str_verts_tri, str_verts_normal, str_tris, str_mats, str_layers = pack_object(obj)

 output = "pico-8 cartridge // http://www.pico-8.com\n"
 output = output.."version 18\n"
 output = output.."__lua__\n\n"
 
 output = output.."-- include files available at https://github.com/jorikemppi/pico-8-bits-and-pieces/tree/master/include\n"
 
 output = output.."\n"

 output = output.."-- general purpose functions\n"
 output = output.."#include include/parse_table.lua\n"
 output = output.."#include include/round.lua\n"
 output = output.."#include include/hex_to_dec.lua\n"
 
 output = output.."\n"
 
 output = output.."-- initialization and object loading functions\n"
 output = output.."#include include/shades.lua\n"
 output = output.."#include include/generate_gradient.lua\n"
 output = output.."#include include/unpack_object.lua\n"
 
 output = output.."\n"
 
 output = output.."-- object handling and transformation functions\n"
 output = output.."-- (you may leave out any functions you don't actually use)\n"
 output = output.."#include include/copy.lua\n"
 output = output.."#include include/dot3d_rotate.lua\n"
 output = output.."#include include/rotate.lua\n"
 output = output.."#include include/translate.lua\n"
 output = output.."#include include/scale.lua\n"
 output = output.."#include include/reflect.lua\n"
 
 output = output.."\n"
 
 output = output.."-- rendering functions\n"
 output = output.."#include include/initialize_render_queue.lua\n"
 output = output.."#include include/flatten_point.lua\n"
 output = output.."#include include/send_to_queue.lua\n"
 output = output.."#include include/render_queue.lua\n"
 output = output.."#include include/trifill.lua\n"
 output = output.."#include include/flat_trifill.lua\n"

 output = output.."\n"
 
 output = output.."function _init()\n"
 output = output.."\n"
 output = output.." obj, material, gradient_start, f = unpack_object({"
 output = output.."\""..str_verts_tri.."\", "
 output = output.."\""..str_verts_normal.."\", "
 output = output.."\""..str_tris.."\", "
 output = output.."\""..str_mats.."\", "
 output = output.."\""..str_layers.."\"}), {}, 0, 0"
 
 gradient_start = 0
 
 for parameter in all(material_parameter) do

  output = output.."\n\n"
  
  output = output.." add(material, {diffuse = "..parameter.diffuse..",\n"
  output = output.."                ambient = "..parameter.ambient..",\n"
  
  output = output.."                curve_patterns = generate_gradient({"
  for i = 1, #parameter.curve_steps do
   output = output..parameter.curve_steps[i]
   if i < #parameter.curve_steps then
    output = output..", "
   end
  end  
  output = output.."}, "..gradient_start.."),\n"
  
  output = output.."                palette_index = "..gradient_start.."})"
  
  gradient_start += #parameter.curve_steps
  
 end
 
 output = output.."\n\n"
 output = output.." material_colors = {"
 
 colorstring = ""
 for parameter in all(material_parameter) do
  for curve_color in all(parameter.curve_colors) do
   colorstring = colorstring..curve_color..", "
  end
 end
 
 colorstring = sub(colorstring, 1, -3)
 
 output = output..colorstring.."}\n\nend\n\n"
 
 output = output.."function _update()\n"
 output = output.." f += 1\n"
 output = output.."end\n\n"
 
 output = output.."function _draw()\n\n"
 
 output = output.." cls()\n\n"
 
 output = output.." for k, v in pairs(material_colors) do\n"
 output = output.."  pal(k - 1, v, 1)\n"
 output = output.." end\n\n"
 
 layers = 0
 for layer in all(obj.layers) do
  layers = max(layer, layers)
 end
 
 output = output.." rq = initialize_render_queue("..layers..")\n\n"
 
 output = output.." newobj = copy(obj)\n"
 output = output.." rotate(newobj, f*0.02, \"x\")\n"
 output = output.." translate(newobj, 0, 0, -5)\n"
 output = output.." send_to_queue(newobj)\n"
 output = output.." render_queue()\n\n"
 
 output = output.."end"
 
 output = output.."\n\n-- internal format (uncomment and copy line below into importer to reload object) --\n"
 output = output.."--!"
 output = output..str_verts_tri.."!"
 output = output..str_verts_normal.."!"
 output = output..str_tris.."!"
 output = output..str_mats.."!"
 output = output..str_layers.."!"
 
 for parameter in all(material_parameter) do
 
  output = output..parameter.diffuse.."|"
  output = output..parameter.ambient.."|"
  
  for i = 1, #parameter.curve_steps do
   output = output..parameter.curve_steps[i]
   if i < #parameter.curve_steps then
    output = output.."_"
   else
    output = output.."|"
   end
  end
  
  for i = 1, #parameter.curve_colors do
   output = output..parameter.curve_colors[i]
   if i < #parameter.curve_colors then
    output = output.."_"
   else
    output = output.."|"
   end
  end
  
 end
  
 printh(output, '@clip')
 
 if (bake_selector == 1) translate(obj, -trans[1], -trans[2], 0)
 
 scale(obj, 1/scale_amount)
 
end

function ui_material_editor_draw_large_gradient()

  for y = 0, 127 do
   line(0, y, 7, y, material[material_selector].curve_patterns[y + 1])
  end
  
  c = material[material_selector].palette_index
   
  for k, y in pairs(material_parameter[material_selector].curve_steps) do
   color(14)
   if (k == step_selector) color(15)
   rect(9, y-1, 15, y+1)
   line(10, y, 14, y, c)
   c += 1
  end

end

__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000007770777007707770777000007770770000000770777077707770077077700000000000000000000000000000000000
00000000000000000000000000000000007070707070000700700000007070707000007070707007007000700007000000000000000000000000000000000000
00000000000000000000000000000000007770777077700700770000007770707000007070770007007700700007000000000000000000000000000000000000
00000000000000000000000000000000007000707000700700700000007070707000007070707007007000700007000000000000000000000000000000000000
00000000000000000000000000000000007000707077000700777000007070707000007700777077007770077007000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000007770777077700770077000000777770000007770077000007770777077700770777077700000000000000000000000000000
00000000000000000000000000007070707070007000700000007700077000000700707000000700777070707070707007000000000000000000000000000000
00000000000000000000000000007770770077007770777000007707077000000700707000000700707077707070770007000000000000000000000000000000
00000000000000000000000000007000707070000070007000007700077000000700707000000700707070007070707007000000000000000000000000000000
00000000000000000000000000007000707077707700770000000777770000000700770000007770707070007700707007000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000770707077707770777077007770000077707700777070707770000000000000000000000000000000000000000
00000000000000000000000000000000000007000707070707070700070700700000007007070707070700700070000000000000000000000000000000000000
00000000000000000000000000000000000007000707077007700770070700700000007007070777070700700000000000000000000000000000000000000000
00000000000000000000000000000000000007000707070707070700070700700000007007070700070700700070000000000000000000000000000000000000
00000000000000000000000000000000000000770077070707070777070700700000077707070700007700700000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000077777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777770000000000000
00000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000
00000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000
00000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000
00000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000
00000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000
00000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000
00000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000
00000000000077777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777770000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000
00000000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000000000
00000000000000000000f0fff0fff0fff00ff0fff0fff00000f0f0fff0f0f0fff0fff0fff00ff0ff00fff0000000000ff0fff0fff0f000000000000000000000
00000000000000000000f00f00fff0f0f0f0f0f0f00f000000f0f0f0f0f0f0f000f000f0f0f0f0f0f00f0000000000f0f0f0f00f00f000000000000000000000
00000000000000000000f00f00f0f0fff0f0f0ff000f000000f0f0fff0f0f0ff00ff00ff00f0f0f0f00f0000000000f0f0ff000f00f000000000000000000000
00000000000000000000f00f00f0f0f000f0f0f0f00f000000fff0f0f0fff0f000f000f0f0f0f0f0f00f0000000000f0f0f0f00f00f000000000000000000000
00000000000000000000f0fff0f0f0f000ff00f0f00f000000fff0f0f00f00fff0f000f0f0ff00f0f00f0000000f00ff00fff0ff00f000000000000000000000
00000000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000000000
00000000000000000000fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000077777777777777777777777777777777777777777777777777777777777777777777777777777777777777777770000000000000000000
00000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000000000
00000000000000000070777077707770077077707770000077707700777077707770770077707000000077700770777077707770777070000000000000000000
00000000000000000070070077707070707070700700000007007070070070007070707070707000000070007070707077707070070070000000000000000000
00000000000000000070070070707770707077000700000007007070070077007700707077707000000077007070770070707770070070000000000000000000
00000000000000000070070070707000707070700700000007007070070070007070707070707000000070007070707070707070070070000000000000000000
00000000000000000070777070707000770070700700000077707070070077707070707070707770000070007700707070707070070070000000000000000000
00000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000000000
00000000000000000077777777777777777777777777777777777777777777777777777777777777777777777777777777777777777770000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000007777777777777777777777777777777777777777777777700000000000000000000000000000000000000000
00000000000000000000000000000000000000007000000000000000000000000000000000000000000000700000000000000000000000000000000000000000
00000000000000000000000000000000000000007007707770777077707770777000000770707077707770700000000000000000000000000000000000000000
00000000000000000000000000000000000000007070007070700070700700700000007000707070707000700000000000000000000000000000000000000000
00000000000000000000000000000000000000007070007700770077700700770000007000707077007700700000000000000000000000000000000000000000
00000000000000000000000000000000000000007070007070700070700700700000007000707070707000700000000000000000000000000000000000000000
00000000000000000000000000000000000000007007707070777070700700777000000770077077707770700000000000000000000000000000000000000000
00000000000000000000000000000000000000007000000000000000000000000000000000000000000000700000000000000000000000000000000000000000
00000000000000000000000000000000000000007777777777777777777777777777777777777777777777700000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

