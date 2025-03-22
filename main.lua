local AnimationClipProvider = game:GetService("AnimationClipProvider")

local Parser = loadstring(game:HttpGet('https://raw.githubusercontent.com/ughhhhhhhhhhhhhhhhbackup/animationLoader/refs/heads/main/Parser.lua'))()
local Player = loadstring(game:HttpGet('https://raw.githubusercontent.com/ughhhhhhhhhhhhhhhhbackup/animationLoader/refs/heads/main/Player.lua'))()

local Interface = {}

function Interface.FromKeyFrames(RootPart: BasePart, KeyframeSequence: KeyframeSequence)
	local Frames = Parser.Parse(RootPart, KeyframeSequence)
	local Track = Player.New(RootPart, Frames)

	return Track
end

function Interface.FromAnimation(RootPart: BasePart, Animation: Animation)
	return Interface.FromKeyFrames(RootPart, AnimationClipProvider:GetAnimationClipAsync(typeof(Animation)~='string' and Animation.AnimationId or Animation))
end

return Interface
