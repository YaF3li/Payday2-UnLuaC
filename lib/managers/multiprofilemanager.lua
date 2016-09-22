MultiProfileManager = MultiProfileManager or class()
function MultiProfileManager:init()
	if not Global.multi_profile then
		Global.multi_profile = {}
	end
	self._global = self._global or Global.multi_profile
	self._global._profiles = self._global._profiles or {}
	self._global._current_profile = self._global._current_profile or 1
	self:_check_amount()
end
function MultiProfileManager:save_current()
	print("[MultiProfileManager:save_current] current profile:", self._global._current_profile)
	local profile = self:current_profile() or {}
	local blm = managers.blackmarket
	local skt = managers.skilltree._global
	profile.primary = blm:equipped_weapon_slot("primaries")
	profile.secondary = blm:equipped_weapon_slot("secondaries")
	profile.melee = blm:equipped_melee_weapon()
	profile.throwable = blm:equipped_grenade()
	profile.deployable = blm:equipped_deployable()
	profile.deployable_secondary = blm:equipped_deployable(2)
	profile.armor = blm:equipped_armor()
	profile.skillset = skt.selected_skill_switch
	profile.perk_deck = Application:digest_value(skt.specializations.current_specialization, false)
	profile.mask = blm:equipped_mask_slot()
	self._global._profiles[self._global._current_profile] = profile
	print("[MultiProfileManager:save_current] done")
end
function MultiProfileManager:load_current()
	local profile = self:current_profile()
	local blm = managers.blackmarket
	local skt = managers.skilltree
	skt:switch_skills(profile.skillset)
	skt:set_current_specialization(profile.perk_deck)
	blm:equip_weapon("primaries", profile.primary)
	blm:equip_weapon("secondaries", profile.secondary)
	blm:equip_melee_weapon(profile.melee)
	blm:equip_grenade(profile.throwable)
	blm:equip_deployable({
		target_slot = 1,
		name = profile.deployable
	})
	blm:equip_deployable({
		target_slot = 2,
		name = profile.deployable_secondary
	})
	blm:equip_armor(profile.armor)
	blm:equip_mask(profile.mask)
	local mcm = managers.menu_component
	if mcm._player_inventory_gui then
		local node = mcm._player_inventory_gui._node
		mcm:close_inventory_gui()
		mcm:create_inventory_gui(node)
	elseif mcm._mission_briefing_gui then
		local node = mcm._mission_briefing_gui._node
		mcm:close_mission_briefing_gui()
		mcm:create_mission_briefing_gui(node)
	end
end
function MultiProfileManager:current_profile_name()
	if not self:current_profile() then
		return "Error"
	end
	return self:current_profile().name or "Profile " .. self._global._current_profile
end
function MultiProfileManager:profile_count()
	return math.max(#self._global._profiles, 1)
end
function MultiProfileManager:set_current_profile(index)
	if index < 0 or index > self:profile_count() then
		return
	end
	if index == self._global._current_profile then
		return
	end
	self:save_current()
	self._global._current_profile = index
	self:load_current()
	print("[MultiProfileManager:set_current_profile] current profile:", self._global._current_profile)
end
function MultiProfileManager:current_profile()
	return self:profile(self._global._current_profile)
end
function MultiProfileManager:profile(index)
	return self._global._profiles[index]
end
function MultiProfileManager:_add_profile(profile, index)
	index = index or #self._global._profiles + 1
	self._global._profiles[index] = profile
end
function MultiProfileManager:next_profile()
	self:set_current_profile(self._global._current_profile + 1)
end
function MultiProfileManager:previous_profile()
	self:set_current_profile(self._global._current_profile - 1)
end
function MultiProfileManager:has_next()
	return self._global._current_profile < self:profile_count()
end
function MultiProfileManager:has_previous()
	return self._global._current_profile > 1
end
function MultiProfileManager:save(data)
	local save_data = deep_clone(self._global._profiles)
	save_data.current_profile = self._global._current_profile
	data.multi_profile = save_data
end
function MultiProfileManager:load(data)
	if data.multi_profile then
		for i, profile in ipairs(data.multi_profile) do
			self:_add_profile(profile, i)
		end
		self._global._current_profile = data.multi_profile.current_profile
	end
	self:_check_amount()
end
function MultiProfileManager:_check_amount()
	local wanted_amount = 5
	if not self:current_profile() then
		self:save_current()
	end
	if wanted_amount < self:profile_count() then
		table.crop(self._global._profiles, wanted_amount)
		self._global._current_profile = math.min(self._global._current_profile, wanted_amount)
	elseif wanted_amount > self:profile_count() then
		local prev_current = self._global._current_profile
		self._global._current_profile = self:profile_count()
		while wanted_amount > self._global._current_profile do
			self._global._current_profile = self._global._current_profile + 1
			self:save_current()
		end
		self._global._current_profile = prev_current
	end
end