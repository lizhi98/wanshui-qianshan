extends RefCounted
## Preserve physical game controls while accepting native/virtual keyboard
## events that carry a logical key and no matching hardware scan code.
static func matches(event:InputEventKey,code:int)->bool:
	return event.physical_keycode==code or event.keycode==code
static func install_logical_fallbacks():
	for action in ["move_left","move_right","move_forward","move_back","jump","sprint","interact","pause","bend_hook","camera_left","camera_right","camera_up","camera_down"]:
		if not InputMap.has_action(action):continue
		var events=InputMap.action_get_events(action)
		for event in events:
			if not event is InputEventKey or event.physical_keycode==0:continue
			var found=false
			for existing in events:
				if existing is InputEventKey and existing.physical_keycode==0 and existing.keycode==event.physical_keycode:found=true;break
			if found:continue
			var logical=event.duplicate();logical.keycode=event.physical_keycode;logical.physical_keycode=0
			InputMap.action_add_event(action,logical)
