-- @description RS5k_manager_MOUSE
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex

  ---------------------------------------------------
  function ShortCuts(char)
    if char == 32 then Main_OnCommandEx(40044, 0,0) end -- space: play/pause
  end
  ---------------------------------------------------
   function MOUSE_Match(mouse, b)
   if not b then return end
     if not b.mouse_offs_x then b.mouse_offs_x = 0 end 
     if not b.mouse_offs_y then b.mouse_offs_y = 0 end
     if b.x and b.y and b.w and b.h then 
       local state= mouse.mx > b.x  + b.mouse_offs_x
               and mouse.mx < b.x+b.w + b.mouse_offs_x
               and mouse.my > b.y - b.mouse_offs_y
               and mouse.my < b.y+b.h - b.mouse_offs_y
       if state and not b.ignore_mouse then mouse.context = b.context 
         return true,  
                 (mouse.mx - b.x- b.mouse_offs_x) / b.w
       end
     end  
   end
   ---------------------------------------------------
   function MOUSE(conf, obj, data, refresh, mouse, pat)
     local d_click = 0.2
     mouse.mx = gfx.mouse_x
     mouse.my = gfx.mouse_y
     mouse.LMB_state = gfx.mouse_cap&1 == 1 
     mouse.RMB_state = gfx.mouse_cap&2 == 2 
     mouse.MMB_state = gfx.mouse_cap&64 == 64
     mouse.Ctrl_LMB_state = gfx.mouse_cap&5 == 5 
     mouse.Ctrl_state = gfx.mouse_cap&4 == 4 
     mouse.Alt_state = gfx.mouse_cap&17 == 17 -- alt + LB
     mouse.wheel = gfx.mouse_wheel
      
     if mouse.last_mx and mouse.last_my and (mouse.last_mx ~= mouse.mx or mouse.last_my ~= mouse.my) then mouse.is_moving = true else mouse.is_moving = false end
     if mouse.last_wheel then mouse.wheel_trig = (mouse.wheel - mouse.last_wheel) end 
     if not mouse.LMB_state_TS then mouse.LMB_state_TS = obj.clock end
     if mouse.LMB_state and mouse.LMB_state_TS and obj.clock -mouse.LMB_state_TS < d_click and obj.clock -mouse.LMB_state_TS  > 0 then  mouse.DLMB_state = true  end 
     if mouse.LMB_state and not mouse.last_LMB_state then  
       mouse.last_mx_onclick = mouse.mx     
       mouse.last_my_onclick = mouse.my 
       mouse.LMB_state_TS = obj.clock
     end    
     if mouse.last_mx_onclick and mouse.last_my_onclick then mouse.dx = mouse.mx - mouse.last_mx_onclick  mouse.dy = mouse.my - mouse.last_my_onclick else mouse.dx, mouse.dy = 0,0 end
   
     
     -- buttons
       for key in spairs(obj) do
         if type(obj[key]) == 'table' and not obj[key].ignore_mouse then
           if not data.parent_track and key ~= 'set_par_tr' then goto skip_until_get_parent_track end
           ------------------------
           if MOUSE_Match(mouse, obj[key]) and obj[key].mouse_overlay then 
             if mouse.LMB_state and not mouse.last_LMB_state and MOUSE_Match(mouse, obj[key]) then if obj[key].func then  obj[key].func() end end
             goto skip_mouse_check 
           end
           ------------------------
           if MOUSE_Match(mouse, obj[key]) then mouse.context = key end
           if MOUSE_Match(mouse, obj[key]) and mouse.LMB_state and not mouse.last_LMB_state then mouse.context_latch = key end
           
           mouse.onclick_L = mouse.LMB_state 
                               and not mouse.last_LMB_state 
                               and not mouse.Ctrl_state  
                               and MOUSE_Match(mouse, obj[key]) 
           if mouse.onclick_L and obj[key].func then obj[key].func() end
                 ------------------------
           mouse.onDclick_L = mouse.LMB_state 
                               and not mouse.last_LMB_state 
                               and not mouse.Ctrl_state  
                               and mouse.DLMB_state 
                               and MOUSE_Match(mouse, obj[key]) 
           if mouse.onDclick_L and obj[key].func_DC then obj[key].func_DC() end
                 ------------------------
           mouse.ondrag_L = -- left drag (persistent even if not moving)
                               mouse.LMB_state 
                               and not mouse.Ctrl_state 
                               and (mouse.context == key or mouse.context_latch == key) 
           if mouse.ondrag_L and obj[key].func_LD then obj[key].func_LD() end 
                 ------------------------
           mouse.ondrag_L_onmove = -- left drag (only when moving after latch)
                               mouse.LMB_state 
                               and not mouse.Ctrl_state 
                               and mouse.is_moving
                               and mouse.context_latch == key
           if mouse.ondrag_L_onmove and obj[key].func_LD2 then obj[key].func_LD2() end 
                 ------------------------              
           mouse.onclick_LCtrl = mouse.LMB_state 
                               and not mouse.last_LMB_state 
                               and mouse.Ctrl_state  
                               and MOUSE_Match(mouse, obj[key]) 
           if mouse.onclick_LCtrl and obj[key].func_trigCtrl then obj[key].func_trigCtrl() end
                 ------------------------            
           mouse.ondrag_LCtrl = -- left drag (persistent even if not moving)
                               mouse.LMB_state 
                               and mouse.Ctrl_state 
                               and (mouse.context == key or mouse.context_latch == key) 
           if mouse.ondrag_LCtrl and obj[key].func_ctrlLD then obj[key].func_ctrlLD() end 
                 ------------------------
           mouse.onclick_R = mouse.RMB_state 
                               and not mouse.last_RMB_state 
                               and not mouse.Ctrl_state  
                               and MOUSE_Match(mouse, obj[key]) 
           if mouse.onclick_R and obj[key].func_R then obj[key].func_R() end
                 ------------------------                
           mouse.ondrag_R = -- left drag (persistent even if not moving)
                               mouse.RMB_state 
                               and not mouse.Ctrl_state 
                               and (mouse.context == key or mouse.context_latch == key) 
           if mouse.ondrag_R and obj[key].func_RD then obj[key].func_RD() end 
                 ------------------------  
           mouse.onwheel = mouse.wheel_trig 
                           and mouse.wheel_trig ~= 0 
                           and not mouse.Ctrl_state 
                           and mouse.context == key
           if mouse.onwheel and obj[key].func_wheel then obj[key].func_wheel(mouse.wheel_trig) end
                 ------------------------          
           ::skip_until_get_parent_track::
           ------------------
         end
       end
       
           
     -- mouse release    
       if mouse.last_LMB_state and not mouse.LMB_state   then          
         -- clear context
           mouse.context_latch = ''
           mouse.context_latch_val = -1
         -- clear export state
           if obj.action_export.state 
             and obj[ mouse.context ] 
             and obj[ mouse.context ].linked_note then
               local note = obj[ mouse.context ].linked_note
               local dest_tr
               if conf.global_mode == 1 or conf.global_mode == 2 then 
                 dest_tr = GetDestTrackByNote(data, conf,data.parent_track, note, true)
                 BuildTrackTemplate_MIDISendMode(conf, data, refresh)
                end
               ExportItemToRS5K(data,conf,refresh, obj.action_export.fn, note, dest_tr)
               
           end
           obj.action_export = {}
         -- clear note
           for i = 1, 127 do StuffMIDIMessage( 0, '0x8'..string.format("%x", 0), i, 100) end
           refresh.GUI = true
           refresh.data = true
       end
       ::skip_mouse_check::
       
       -- reset latch anyway
       if mouse.last_LMB_state and not mouse.LMB_state   then  
         -- clear context
           mouse.context_latch = ''
           mouse.context_latch_val = -1
       end      
       
       mouse.last_mx = mouse.mx
       mouse.last_my = mouse.my
       mouse.last_LMB_state = mouse.LMB_state  
       mouse.last_RMB_state = mouse.RMB_state
       mouse.last_MMB_state = mouse.MMB_state 
       mouse.last_Ctrl_LMB_state = mouse.Ctrl_LMB_state
       mouse.last_Ctrl_state = mouse.Ctrl_state
       mouse.last_Alt_state = mouse.Alt_state
       mouse.last_wheel = mouse.wheel   
       mouse.last_context_latch = mouse.context_latch
       mouse.DLMB_state = nil  
       
       -- DragnDrop from MediaExplorer 5.91pre1+
       if obj.reapervrs >= 5.91 then
         local DRret, DRstr = gfx.getdropfile(0)
         if    DRret ~= 0  
               and obj[ mouse.context ] 
               and obj[ mouse.context ].linked_note then
           local note = obj[ mouse.context ].linked_note
           local dest_tr
           if conf.global_mode == 1 or conf.global_mode == 2 then 
             dest_tr = GetDestTrackByNote(data, conf,data.parent_track, note, true)
             BuildTrackTemplate_MIDISendMode(conf, data, refresh)
           end
           ExportItemToRS5K(data,conf,refresh, DRstr, note, dest_tr)                 
         end
       end      
   end
