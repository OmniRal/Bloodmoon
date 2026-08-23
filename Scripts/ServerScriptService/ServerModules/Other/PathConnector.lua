-- OmniRal

local PathConnector = {}

local MAX_POINTS = 100

local LETTERS = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"}
local LETTER_COLORS = {
    Color3.fromRGB(0, 162, 255),
    Color3.fromRGB(0, 255, 42),
    Color3.fromRGB(255, 72, 0),
    Color3.fromRGB(143, 58, 255),
    Color3.fromRGB(252, 255, 58),
    Color3.fromRGB(234, 74, 255),
    Color3.fromRGB(255, 137, 58),

    Color3.fromRGB(71, 187, 255),
    Color3.fromRGB(72, 255, 102),
    Color3.fromRGB(255, 123, 71),
    Color3.fromRGB(174, 112, 255),
    Color3.fromRGB(253, 255, 125),
    Color3.fromRGB(244, 160, 255),
    Color3.fromRGB(255, 182, 133),

    Color3.fromRGB(0, 107, 168),
    Color3.fromRGB(0, 180, 30),
    Color3.fromRGB(167, 47, 0),
    Color3.fromRGB(92, 25, 179),
    Color3.fromRGB(165, 168, 0),
    Color3.fromRGB(165, 37, 182),
    Color3.fromRGB(151, 76, 25),

    Color3.fromRGB(180, 227, 255),
    Color3.fromRGB(170, 255, 184),
    Color3.fromRGB(255, 196, 172),
    Color3.fromRGB(219, 191, 255),
    Color3.fromRGB(254, 255, 205),
    Color3.fromRGB(244, 160, 255),
    Color3.fromRGB(255, 223, 202),
}

local function Cleanup(This: Instance)
	for _, Thing in This:GetChildren() do
		Thing:Destroy()
	end
end

local function ConnectTwoPoints(Point_1: BasePart, Point_2: BasePart, Color: Color3)
    local Attachment_0 = Instance.new("Attachment")
    Attachment_0.Name = Point_1.Name .. "-" .. Point_2.Name .. "_A"
    Attachment_0.Parent = Point_1

    local Attachment_1 = Instance.new("Attachment")
    Attachment_1.Name = Point_1.Name .. "-" .. Point_2.Name .. "_B"
    Attachment_1.Parent = Point_2

    local Beam = Instance.new("Beam")
    Beam.FaceCamera = true
    Beam.Name = "Beam_To_" .. Point_2.Name
    Beam.Attachment0 = Attachment_0
    Beam.Attachment1 = Attachment_1
    Beam.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color), ColorSequenceKeypoint.new(1, Color)}
    Beam.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0)}
    Beam.Parent = Point_1
end

function PathConnector.Run(Folder: Folder, BranchConnections: { {string} })
    if not Folder then return end

	local LastLetterExists = false
	
	for _, Node in Folder:GetChildren() do
		if not Node then continue end
		Cleanup(Node)
	end
    
    for Num, Letter in ipairs(LETTERS) do
        for x = 1, MAX_POINTS - 1 do
            local Point_1, Point_2 = Folder:FindFirstChild(Letter .. x), Folder:FindFirstChild(Letter .. x + 1)
            if not Point_1 then
                LastLetterExists = false
                break
            end

            if Point_1 and Point_2 then
				LastLetterExists = true
				
                ConnectTwoPoints(Point_1, Point_2, LETTER_COLORS[Num])
			else
				break
			end
        end

        if LastLetterExists then continue end

        break
    end

    if not BranchConnections then return end

    for _, Pair in BranchConnections do
        if not Pair[1] or not Pair[2] then continue end
        local Point_1, Point_2 = Folder:FindFirstChild(Pair[1]), Folder:FindFirstChild(Pair[2])
        if not Point_1 or not Point_2 then continue end

        local Color: Color3
        for Num, Letter in ipairs(LETTERS) do
            if string.sub(Pair[1], 1, 1) ~= Letter then continue end
            Color = LETTER_COLORS[Num]
            break
        end

        if not Color then continue end

        ConnectTwoPoints(Point_1, Point_2, Color)
    end
end

return PathConnector