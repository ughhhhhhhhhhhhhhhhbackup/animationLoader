local Parser = {}

function Parser.__RecursiveGetPoses(Parent: Keyframe | Pose, Poses)
	Poses = Poses or {}

	for _, Pose: Pose in Parent:GetChildren() do
		Poses[Pose.Name] = Pose
		Parser.__RecursiveGetPoses(Pose, Poses)
	end

	return Poses
end

function Parser.__RecursiveGetMotors(Part: BasePart, Motors, Blacklist)
	Blacklist = Blacklist or {}
	Motors = Motors or {}

	for _, Motor: Motor6D in Part:GetJoints() do
		if not Motor:IsA("Motor6D") or Blacklist[Motor] then
			continue
		end

		local Part = Motor.Part1

		Blacklist[Motor] = true
		Motors[Part.Name] = Motor

		Parser.__RecursiveGetMotors(Part, Motors, Blacklist)
	end

	return Motors
end

function Parser.Parse(RootPart: BasePart, Sequence: KeyframeSequence)
	local Motors: {Motor6D} = Parser.__RecursiveGetMotors(RootPart)

	local Frames: {Frame} = {}
	local LastPoses = {}

	for _, Frame: Keyframe in Sequence:GetChildren() do
		if Frame:IsA('Keyframe') then
			local Target = {}

			for _, Pose: Pose in Parser.__RecursiveGetPoses(Frame) do
				local Motor = Motors[Pose.Name]
				if not Motor then
					continue
				end
				Motor:SetAttribute('OriginalC0',Motor.C0);
				Target[Motor] = Pose
				LastPoses[Motor] = Pose
			end

			for Motor, Pose in LastPoses do
				if Target[Motor] then
					continue
				end

				Target[Motor] = Pose
			end

			table.insert(Frames, {
				Time = Frame.Time,
				Target = Target
			})
		end
	end

	table.sort(Frames, function(A, B)
		return A.Time < B.Time
	end)

	return Frames
end

return Parser
