--!strict
-- CreatureModel: builds a cute blocky critter out of parts (no external assets
-- needed) so creatures look like characters instead of plain cubes. Rarer
-- creatures get a glow light and sparkle particles.

local CreatureModel = {}

local GLOW_MULT = 50 -- rarity income at/above this gets a light + particles
local NEON_MULT = 140 -- ...and a neon body

local function ball(name: string, diameter: number, color: Color3, parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(diameter, diameter, diameter)
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- Builds the creature centered at `anchorCFrame`, facing +Z (toward the owner).
function CreatureModel.build(rarity, anchorCFrame: CFrame): Model
	local model = Instance.new("Model")
	local p = anchorCFrame.Position

	local body = ball("Body", 3, rarity.color, model)
	body.Position = p
	if rarity.mult >= NEON_MULT then
		body.Material = Enum.Material.Neon
	end
	model.PrimaryPart = body

	ball("EarL", 1.1, rarity.color, model).Position = p + Vector3.new(-0.9, 1.6, 0)
	ball("EarR", 1.1, rarity.color, model).Position = p + Vector3.new(0.9, 1.6, 0)

	local footColor = rarity.color:Lerp(Color3.new(0, 0, 0), 0.3)
	ball("FootL", 1.0, footColor, model).Position = p + Vector3.new(-0.8, -1.6, 0.2)
	ball("FootR", 1.0, footColor, model).Position = p + Vector3.new(0.8, -1.6, 0.2)

	ball("EyeL", 0.8, Color3.new(1, 1, 1), model).Position = p + Vector3.new(-0.6, 0.4, 1.0)
	ball("EyeR", 0.8, Color3.new(1, 1, 1), model).Position = p + Vector3.new(0.6, 0.4, 1.0)
	ball("PupL", 0.36, Color3.new(0, 0, 0), model).Position = p + Vector3.new(-0.6, 0.45, 1.35)
	ball("PupR", 0.36, Color3.new(0, 0, 0), model).Position = p + Vector3.new(0.6, 0.45, 1.35)

	if rarity.mult >= GLOW_MULT then
		local light = Instance.new("PointLight")
		light.Color = rarity.color
		light.Range = 10
		light.Brightness = 3
		light.Parent = body

		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkles.Rate = 10
		sparkles.Lifetime = NumberRange.new(0.6, 1.1)
		sparkles.Speed = NumberRange.new(0.5, 1.5)
		sparkles.Size = NumberSequence.new(0.6)
		sparkles.Color = ColorSequence.new(rarity.color)
		sparkles.Parent = body
	end

	return model
end

return CreatureModel
