-- OmniRal

--Enathri was here ^-^

local CustomEnum = {}

export type Currency = "None" | "Gold" | "Robux"

export type UnlockedBy = "Default" | "Coins" | "Robux" | "Other"

export type AttackType = "Melee" | "Ranged"
export type DamageType = "Physical" | "Magical" | "Pure"
export type AbilityType = "Active" | "Passive"

export type RoomPadType = "Public" | "Private" | "Friends"

CustomEnum.RootWalkSpeed = 16

CustomEnum.ReturnCodes = {
    ["ComplexError"] = -9,
    ["Dead"] = -8,
    ["OnCooldown"] = -7,
    ["MissingData"] = -6,
}

CustomEnum.RayType = {
    LineRaycast = "LineRaycast",
    BlockRaycast = "BlockRaycast",
}

export type TeleportInfo = {
    MissionID: number,
    ExpectedPlayers: {{Name: string, ID: number}}
}

export type Product = {
    Type: "Coins" | "Toy",
    Name: string,
    Detail: number | string?
}

export type Ability = {
    Name: string,
    DisplayName: string,
    Description: string,
    FlavorText: string,
    Icon: number,

    Type: AbilityType,
    Damage: NumberRange,
    Cooldown: number,

    Details: {}?
}

export type EasingStyle = "Sine" | "Quad" | "Quint" | "Cubic" | "Back" | "Bounce" | "Elastic"
export type EasingDirection = "In" | "Out" | "InOut"

export type PartBuildData = {
    Name: string,
    PivotOffset: CFrame?,
    Attached: {To: string, CF: CFrame}?,
    Start: {Frame: number, CF: CFrame, Angles: Vector3, Size: Vector3},
    End: {Frame: number, CF: CFrame, Angles: Vector3, Size: Vector3, Transparency: number?},
    Easing: {Style: EasingStyle, Direction: EasingDirection, Details: {[string]: number}?}?
}

export type BuildTimeline = {
    MaxKeyframes: number,
    Scaler: number?,
    Parts: {
        PartBuildData
    }
}

return CustomEnum