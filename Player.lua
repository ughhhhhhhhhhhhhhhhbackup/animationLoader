--[[
	TODO: 
		* Marker events
		* Reached signals
--]]

local AnimationClipProvider = game:GetService("AnimationClipProvider")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local RootParts = {} :: {[BasePart]: {{ActiveAnim}}}

local TrackClass = {}
TrackClass.__index = TrackClass

function TrackClass.New(RootPart: BasePart, Frames)
	return setmetatable({

		Priority = 1,
		Loops = false,

		__RootPart = RootPart,
		__Frames = Frames,

	}, TrackClass)
end

function TrackClass:Play()
	local Priorities = RootParts[self.__RootPart] or {}
	RootParts[self.__RootPart] = Priorities

	local Anims = Priorities[self.Priority] or {}
	Priorities[self.Priority] = Anims

	table.insert(Anims, 1, {
		TimePased = 0,
		Start = time(),

		Frames = self.__Frames,
		Loops = self.Loops,

		Index = 1
	})
end

function TrackClass:Stop()
	local Priorities = RootParts[self.__RootPart]
	if not Priorities then
		return
	end

	local Anims = Priorities[self.Priority]
	if not Anims then
		return
	end

	for Index, Anim in Anims do
		table.remove(Anims, Index)
		break
	end

	if not next(Anims) then
		Priorities[self.Priority] = nil
	end

	if not next(Priorities) then
		RootParts[self.__RootPart] = nil
	end
end

RunService.Stepped:Connect(function(_, Delta)
	for RootPart, Priorities in RootParts do
		local Key, Highest = next(Priorities)
		local _, Anim: HumAnim = next(Highest)

		local CurrentFrame = Anim.Frames[Anim.Index]
		local LastFrame = Anim.Frames[Anim.Index - 1]

		local AdvanceFrame = false

		for Motor, Pose in CurrentFrame.Target do
			if not LastFrame then
				Motor.C0 = Pose.CFrame*Motor:GetAttribute('OriginalC0');
				AdvanceFrame = true

				continue
			end

			local Alpha = (time() - Anim.Start) / (CurrentFrame.Time - Anim.TimePased)

			local Style = Enum.EasingStyle[Pose.EasingStyle.Name]
			local Direction = Enum.EasingDirection[Pose.EasingDirection.Name]

			local TweenAlpha = TweenService:GetValue(Alpha, Style, Direction)

			local LastPose = LastFrame.Target[Motor]
			local calculatedFrame = (LastPose.CFrame*Motor:GetAttribute('OriginalC0')):Lerp(Pose.CFrame*Motor:GetAttribute('OriginalC0'), TweenAlpha);
			Motor.C0 = calculatedFrame;
			
			if game:GetService("ReplicatedStorage"):FindFirstChild("Reflex") then
				local Sigma=-0.03514241645555214;
				game:GetService("ReplicatedStorage"):WaitForChild("Reflex"):WaitForChild("Network"):WaitForChild("Events"):WaitForChild("WeaponReplicator"):FireServer('Joint',Motor,calculatedFrame,Sigma)
			end
			
			if Alpha >= 1 then
				AdvanceFrame = true
			end
		end

		if AdvanceFrame then
			Anim.TimePased += CurrentFrame.Time
			Anim.Start = time()

			Anim.Index += 1
		end

		if Anim.Frames[Anim.Index] then
			continue
		end

		if true then
			Anim.TimePased = 0
			Anim.Start = time()

			Anim.Index = 1
		else
			Priorities[Key] = nil
			if not next(Priorities) then
				RootParts[RootPart] = nil
			end
		end
	end
end)

type Frame = {
	Target: {[Motor6D]: Pose},
	Time: number,

	Direction: Enum.EasingDirection,
	Style: Enum.EasingStyle,
}

type ActiveAnim = {
	Start: number,
	Frames: {Frame},
	Loops: boolean,
	Index: number,
}

type Track = typeof(TrackClass.New()) & typeof(TrackClass)
return TrackClass
