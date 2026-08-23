-- OmniRal

export type Enemy = {
    DisplayName: string,
    BaseHealth: number,
    MoveSpeed: number,
    AnimSpeed: number,
    Animations: {
        [string]: {ID: number, Priority: Enum.AnimationPriority}
    },
}

local EnemyInfo: {
    [string]: Enemy
} = {}

EnemyInfo["TestEnemy"] = {
    DisplayName = "Test Enemy",
    BaseHealth = 100,
    MoveSpeed = 9,
    AnimSpeed = 2,
    Animations = {
        ["Move"] = {ID = 72328487976711, Priority = Enum.AnimationPriority.Movement}
    },
}

return EnemyInfo