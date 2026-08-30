-- OmniRal

local UnitEnum = {}

UnitEnum.BaseAttributeLimits = {
    Health = NumberRange.new(0, math.huge),
    Mana = NumberRange.new(0, math.huge),
    CooldownReduction = NumberRange.new(0, 75),
}

UnitEnum.DefaultHistoryEntryCleanTime = 7

export type UnitValues = {
    Base: BaseAttributes,
    Offsets: BaseAttributes,
    States: BaseStates,

    Effects: {},
    History: {},
    Folder: Folder,
}

export type BaseAttributes = {
    Health: number?,
    HealthGain: number?,

    Mana: number?,
    ManaGain: number?,

    Armor: number?,
    WalkSpeed: number?, 
    AttackSpeed: number?,
    CritPercent: number?,
    CritChance: number?,
    Damage: number?,

    CooldownReduction: number?
}

export type BaseStates = {
    Immune: boolean?,
    Silenced: boolean?,
    Disarmed: boolean?,
    Break: boolean?,
    Rooted: boolean?,
    Stunned: boolean?,
    Tracked: boolean?,
    Panic: {Active: boolean, From: Vector3?}?,
    Taunt: {Active: boolean, Goal: Vector3? | BasePart?}?,
}

-- The structure of an actual effect (buff / debuff)
export type Effect = {
	From: Player | Model | string,
    IsDebuff: boolean,

    Name: string,
    Icon: number?,
    Description: string?,

    SpawnTime: number,
    Duration: number,
    MaxStacks: number,
    NumberStack: boolean?,
    Amount: number?,
    
    Attributes: {[string]: number},
    States: {[string]: {Active: boolean, Point: string | CFrame?}},

    CleanDelay: thread,
    CleanFunction: (...any) -> (...any),

    Config: Configuration?,
}

-- Used when constructing a new effect
export type EffectDetails = {
	From: Player | Model | string,
    Name: string, 
    Icon: number?, 
    Description: string?, 
    IsDebuff: boolean?, 
    Duration: number, 
    MaxStacks: number,
    DoNotDisplay: boolean?,
}

export type HistoryEntryType = "DamageDealt" | "DamageTaken" | "CastedHeal" | "ReceivedHeal"

export type HistoryEntry = {
    Source: string?,
    
    Name: string,
    Type: HistoryEntryType,
    TimeAdded: number?,
    CleanTime: number?,

    Amount: number?,
}

return UnitEnum