scriptname SeedUtil hidden

LastSeedAPI function GetAPI() global
    return (Game.GetFormFromFile(0x0000B16A, "LastSeed.esp") as Quest) as LastSeedAPI
endFunction

; Public Enums ====================================================================================

; Food ID
int property FOODTYPE_BREAD             = 1     autoReadOnly
int property FOODTYPE_MEAT_RAW          = 2     autoReadOnly
int property FOODTYPE_MEAT_COOKED       = 3     autoReadOnly
int property FOODTYPE_SMALLGAME_RAW     = 4     autoReadOnly
int property FOODTYPE_SMALLGAME_COOKED  = 5     autoReadOnly
int property FOODTYPE_FISH_RAW          = 6     autoReadOnly
int property FOODTYPE_FISH_COOKED       = 7     autoReadOnly
int property FOODTYPE_SEAFOOD_RAW       = 8     autoReadOnly
int property FOODTYPE_SEAFOOD_COOKED    = 9     autoReadOnly
int property FOODTYPE_VEGETABLE         = 10    autoReadOnly
int property FOODTYPE_FRUIT             = 11    autoReadOnly
int property FOODTYPE_CHEESE            = 12    autoReadOnly
int property FOODTYPE_TREAT             = 13    autoReadOnly
int property FOODTYPE_PASTRY            = 14    autoReadOnly
int property FOODTYPE_STEW              = 15    autoReadOnly
int property FOODTYPE_CHEESEBOWL        = 16    autoReadOnly
int property DRINKTYPE_MILK             = 17    autoReadOnly
int property DRINKTYPE_ALCOHOLIC        = 18    autoReadOnly
int property DRINKTYPE_NONALCOHOLIC     = 19    autoReadOnly

; System Access ===================================================================================

; These are not intended for public use and are therefore undocumented.

_Seed_VitalitySystem function GetVitalitySystem() global
    LastSeedAPI LastSeed = GetAPI()
    if LastSeed == none
        RaiseSeedAPIError()
        return none
    endif
    return LastSeed.Vitality
endFunction

_Seed_HungerSystem function GetHungerSystem() global
    LastSeedAPI LastSeed = GetAPI()
    if LastSeed == none
        RaiseSeedAPIError()
        return none
    endif
    return LastSeed.Hunger
endFunction

_Seed_ThirstSystem function GetThirstSystem() global
    LastSeedAPI LastSeed = GetAPI()
    if LastSeed == none
        RaiseSeedAPIError()
        return none
    endif
    return LastSeed.Thirst
endFunction

_Seed_FatigueSystem function GetFatigueSystem() global
    LastSeedAPI LastSeed = GetAPI()
    if LastSeed == none
        RaiseSeedAPIError()
        return none
    endif
    return LastSeed.Fatigue
endFunction

_Seed_SpoilSystem function GetSpoilageSystem() global
    LastSeedAPI LastSeed = GetAPI()
    if LastSeed == none
        RaiseSeedAPIError()
        return none
    endif
    return LastSeed.Spoil
endFunction

_Seed_VitalityMeterInterfaceHandler function GetVitalityMeterHandler() global
    LastSeedAPI LastSeed = GetAPI()
    if LastSeed == none
        RaiseSeedAPIError()
        return none
    endif
    return LastSeed.VitalityMeterHandler
endFunction

_Seed_HungerMeterInterfaceHandler function GetHungerMeterHandler() global
    LastSeedAPI LastSeed = GetAPI()
    if LastSeed == none
        RaiseSeedAPIError()
        return none
    endif
    return LastSeed.HungerMeterHandler
endFunction

;/_Seed_ThirstMeterInterfaceHandler function GetThirstMeterHandler() global
    LastSeedAPI LastSeed = GetAPI()
    if LastSeed == none
        RaiseSeedAPIError()
        return none
    endif
    return LastSeed.ThirstMeterHandler
endFunction

_Seed_FatigueMeterInterfaceHandler function GetFatigueMeterHandler() global
    LastSeedAPI LastSeed = GetAPI()
    if LastSeed == none
        RaiseSeedAPIError()
        return none
    endif
    return LastSeed.FatigueMeterHandler
endFunction
/;
_Seed_FoodDatastoreHandler function GetFoodDatastoreHandler() global
    LastSeedAPI LastSeed = GetAPI()
    if LastSeed == none
        RaiseSeedAPIError()
        return none
    endif
    return LastSeed.FoodDatastore
endFunction

_Seed_Compatibility function GetCompatibilitySystem() global
    LastSeedAPI LastSeed = GetAPI()
    if LastSeed == none
        RaiseSeedAPIError()
        return none
    endif
    return LastSeed.Compatibility
endFunction

FallbackEventEmitter function GetEventEmitter_LastSeedLoaded() global
    LastSeedAPI LastSeed = GetAPI()
    if LastSeed == none
        RaiseSeedAPIError()
        return none
    endif
    return LastSeed.EventEmitter_LastSeedLoaded as FallbackEventEmitter
endFunction

; Public Functions ================================================================================

;/********f* SeedUtil/GetAPIVersion
* API VERSION ADDED
* 1
*
* DESCRIPTION
* Get the SeedUtil API version number.
*
* SYNTAX
*/;
float function GetAPIVersion() global
;/*
* PARAMETERS
* None
*
* RETURN VALUE
* The SeedUtil API version number. This is NOT the same thing as the version number of Last Seed.
* SeedUtil's API version number will increment only when changes have been made to the API itself.
*
* EXAMPLES
float ver = SeedUtil.GetAPIVersion()
;*********/;
    LastSeedAPI LastSeed = GetAPI()
    if LastSeed == none
        RaiseSeedAPIError()
        return -1.0
    endif
    return LastSeed._Seed_APIVersion.GetValue()
endFunction

;/********f* SeedUtil/GetLastSeedVersion
* API VERSION ADDED
* 1
*
* DESCRIPTION
* Get the Last Seed mod version number.
*
* SYNTAX
*/;
float function GetLastSeedVersion() global
;/*
* PARAMETERS
* None
*
* RETURN VALUE
* The Last Seed version number.
*
* EXAMPLES
float ver = SeedUtil.GetFrostfallVersion()
;*********/;
    LastSeedAPI LastSeed = GetAPI()
    if LastSeed == none
        RaiseSeedAPIError()
        return -1.0
    endif
    return LastSeed._Seed_LastSeedVersion.GetValue()
endFunction

;/********f* SeedUtil/IsPlayerFocused
* API VERSION ADDED
* 1
*
* DESCRIPTION
* Returns whether or not the player is 'focused' (e.g. in a dungeon or other qualifying area
* that temporarily delays needs and Vitality).
*
* SYNTAX
*/;
bool function IsPlayerFocused() global
;/*
* PARAMETERS
* None
*
* RETURN VALUE
* True if the player is focused; false otherwise.
*
* EXAMPLES
;Is the player focused?
bool isFocused = SeedUtil.IsPlayerFocused()
;*********/;
    LastSeedAPI LastSeed = GetAPI()
    if LastSeed == none
        RaiseSeedAPIError()
        return false
    endif

    if LastSeed._Seed_IsPlayerFocused.GetValueInt() == 2
        return true
    else
        return false
    endif
endFunction

;/********f* SeedUtil/GetFoodType
* API VERSION ADDED
* 1
*
* DESCRIPTION
* Returns this food's type, if any.
*
* SYNTAX
*/;
int function GetFoodType(Potion akFood) global
;/*
* PARAMETERS
* akFood: The form to check.
*
* RETURN VALUE
* 0:                                This item is not food, or has no known type.
* FOODTYPE_BREAD (1):               This item is Bread.
* FOODTYPE_MEAT_RAW (2):            This item is Large Meat (Raw).
* FOODTYPE_MEAT_COOKED (3):         This item is Large Meat (Cooked).
* FOODTYPE_SMALLGAME_RAW (4):       This item is Small Game (Raw).
* FOODTYPE_SMALLGAME_COOKED (5):    This item is Small Game (Cooked).
* FOODTYPE_FISH_RAW (6):            This item is Fish (Raw).
* FOODTYPE_FISH_COOKED (7):         This item is Fish (Cooked).
* FOODTYPE_SEAFOOD_RAW (8):         This item is Seafood (Raw).
* FOODTYPE_SEAFOOD_COOKED (9):      This item is Seafood (Cooked).
* FOODTYPE_VEGETABLE (10):          This item is a Vegetable.
* FOODTYPE_FRUIT (11):              This item is Fruit.
* FOODTYPE_CHEESE (12):             This item is Cheese (sliced, unpreserved).
* FOODTYPE_TREAT (13):              This item is a Treat.
* FOODTYPE_PASTRY (14):             This item is a Pastry.
* FOODTYPE_STEW (15):               This item is Stew.
* FOODTYPE_CHEESEBOWL (16):         This item is a Cheese Bowl.
* DRINKTYPE_MILK (17):              This item is Milk.
* DRINKTYPE_ALCOHOLIC (18):         This item is an Alcoholic Drink.
* DRINKTYPE_NONALCOHOLIC (19):      This item is a Non-Alcoholic Drink.
*
* EXAMPLES
;Is the spongecake a bread, or a treat?
int result = SeedUtil.GetFoodType(cake)
if result == SeedUtil.FOODTYPE_BREAD
    Debug.trace("It's bread!")
elseif result == SeedUtil.FOODTYPE_TREAT
    Debug.trace("It's a treat!")
endif
;*********/;
    LastSeedAPI LastSeed = GetAPI()
    if LastSeed == none
        RaiseSeedAPIError()
        return -1
    endif

    return LastSeed.FoodDatastore.IdentifyFood(akFood)
endFunction

;/********f* SeedUtil/SetFoodType
* API VERSION ADDED
* 1
*
* DESCRIPTION
* Sets the food's identity to the provided type.
*
* SYNTAX
*/;
function SetFoodType(Potion akFood, int aiType) global
;/*
* PARAMETERS
* akFood: The food to set the type of.
* aiType: The food's type. See below.
* FOODTYPE_BREAD (1):               This item is Bread.
* FOODTYPE_MEAT_RAW (2):            This item is Large Meat (Raw).
* FOODTYPE_MEAT_COOKED (3):         This item is Large Meat (Cooked).
* FOODTYPE_SMALLGAME_RAW (4):       This item is Small Game (Raw).
* FOODTYPE_SMALLGAME_COOKED (5):    This item is Small Game (Cooked).
* FOODTYPE_FISH_RAW (6):            This item is Fish (Raw).
* FOODTYPE_FISH_COOKED (7):         This item is Fish (Cooked).
* FOODTYPE_SEAFOOD_RAW (8):         This item is Seafood (Raw).
* FOODTYPE_SEAFOOD_COOKED (9):      This item is Seafood (Cooked).
* FOODTYPE_VEGETABLE (10):          This item is a Vegetable.
* FOODTYPE_FRUIT (11):              This item is Fruit.
* FOODTYPE_CHEESE (12):             This item is Cheese (sliced, unpreserved).
* FOODTYPE_TREAT (13):              This item is a Treat.
* FOODTYPE_PASTRY (14):             This item is a Pastry.
* FOODTYPE_STEW (15):               This item is Stew.
* FOODTYPE_CHEESEBOWL (16):         This item is a Cheese Bowl.
* DRINKTYPE_MILK (17):              This item is Milk.
* DRINKTYPE_ALCOHOLIC (18):         This item is an Alcoholic Drink.
* DRINKTYPE_NONALCOHOLIC (19):      This item is a Non-Alcoholic Drink.
*
* RETURN VALUE
* None.
*
* EXAMPLES
;Set the spongecake as a treat.
SeedUtil.SetFoodType(cake, SeedUtil.FOODTYPE_TREAT)
* NOTES
* * The type of base game food (from Skyrim and any DLC)
* cannot be set to a different value.
* * Do not set a single food to multiple types. The system
* does not check if a food is already set as a different type.
* If the food had its type set via script previously, use
* SeedUtil.UnsetFoodType() first, and then set the new type.
;*********/;
    LastSeedAPI LastSeed = GetAPI()
    if LastSeed == none
        RaiseSeedAPIError()
        return
    endif

    LastSeed.FoodDatastore.AddFoodIdentity(akFood, aiType)
endFunction

;/********f* SeedUtil/UnsetFoodType
* API VERSION ADDED
* 1
*
* DESCRIPTION
* Unsets the food's identity from the provided type.
*
* SYNTAX
*/;
function UnsetFoodType(Potion akFood, int aiType) global
;/*
* PARAMETERS
* akFood: The food to unset the type of.
* aiType: The food's current type. See below.
* 1:    This item is Bread.
* 2:    This item is Large Meat (Raw).
* 3:    This item is Large Meat (Cooked).
* 4:    This item is Small Game (Raw).
* 5:    This item is Small Game (Cooked).
* 6:    This item is Fish (Raw).
* 7:    This item is Fish (Cooked).
* 8:    This item is Seafood (Raw).
* 9:    This item is Seafood (Cooked).
* 10:   This item is a Vegetable.
* 11:   This item is Fruit.
* 12:   This item is Cheese (sliced, unpreserved).
* 13:   This item is a Treat.
* 14:   This item is a Pastry.
* 15:   This item is Stew.
* 16:   This item is a Cheese Bowl.
* 17:   This item is Milk.
* 18:   This item is an Alcoholic Drink.
* 19:   This item is a Non-Alcoholic Drink.
*
* RETURN VALUE
* None.
*
* EXAMPLES
;Unset the spongecake as a treat.
SeedUtil.UnsetFoodType(cake, 13)
* NOTES
* The type of base game food (from Skyrim and any DLC)
* cannot be unset.
;*********/;
    LastSeedAPI LastSeed = GetAPI()
    if LastSeed == none
        RaiseSeedAPIError()
        return
    endif

    LastSeed.FoodDatastore.RemoveFoodIdentity(akFood, aiType)
endFunction

;/********f* SeedUtil/IsFoodPreserved
* API VERSION ADDED
* 1
*
* DESCRIPTION
* Whether or not the food is "preserved" (does not spoil).
*
* SYNTAX
*/;
bool function IsFoodPreserved(Potion akFood) global
;/*
* PARAMETERS
* akFood: The food to check.
*
* RETURN VALUE
* True:     The food is preserved and does not spoil.
* False:    The food is not preserved and will spoil, 
*           if that setting is enabled.
*
* EXAMPLES
Debug.trace("Will the twinkie ever spoil?")
bool result = SeedUtil.IsFoodPreserved(twinkie)
if result == false
    Debug.trace("Guess not.")
endif
* NOTES
* Drinks of type Alcoholic and Non-Alcoholic always return 'true'.
;*********/;
    LastSeedAPI LastSeed = GetAPI()
    if LastSeed == none
        RaiseSeedAPIError()
        return false
    endif

    return LastSeed.FoodDatastore.IsFoodPreserved(akFood)
endFunction

;/********f* SeedUtil/SetFoodPreserved
* API VERSION ADDED
* 1
*
* DESCRIPTION
* Set whether or not the food is preserved.
*
* SYNTAX
*/;
function SetFoodPreserved(Potion akFood, bool abIsPreserved = true) global
;/*
* PARAMETERS
* akFood: The food to set.
* abIsPreserved (optional): Whether or not the food is
*                           preserved. Default: True.
*
* RETURN VALUE
* None.
*
* EXAMPLES
;Set the spongecake to never spoil.
SeedUtil.SetFoodPreserved(cake)

;Set the waffle to spoil (if previously set to spoil).
SeedUtil.SetFoodPreserved(waffle, false)
* NOTES
* Food defaults to not being preserved; there is no need to call
* this function to mark it as "not preserved".
;*********/;
    LastSeedAPI LastSeed = GetAPI()
    if LastSeed == none
        RaiseSeedAPIError()
        return
    endif

    LastSeed.FoodDatastore.SetFoodPreserved(akFood, abIsPreserved)
endFunction

;/********f* SeedUtil/GetFoodMaxPerishDurationByType
* API VERSION ADDED
* 1
*
* DESCRIPTION
* Whether or not the food is "preserved" (does not spoil).
*
* SYNTAX
*/;
int function GetFoodMaxPerishDurationByType(int aiFoodType) global
;/*
* PARAMETERS
* aiFoodType: The food type to check. -1 indicates an invalid type, or this food does not spoil.
*
* RETURN VALUE
* The duration (in hours) it takes this type of food to spoil to the next stage.
*
* EXAMPLES
Debug.trace("How many hours does it take raw fish to spoil?")
int result = SeedUtil.GetFoodMaxPerishDurationByType(6)
;*********/;
    
    if aiFoodType < 1 || aiFoodType > 17
        return -1
    endif

    int t = aiFoodType

    if t == 2 || t == 4 || t == 6 || t == 8
        ; Raw meat, game, fish, and seafood
        return 24

    elseif t == 3 || t == 5 || t == 7 || t == 9
        ; Cooked meat, game, fish, and seafood
        return 60

    elseif t == 1 || t == 10 || t == 11 || t == 12 || t == 14 || t == 16 || t == 17
        ; Bread, vegetables, fruit, cheese, pastries, cheese bowls, and milk
        return 120

    elseif t == 13 || t == 15
        ; Treats and stews
        return 168

    endif

    return -1
endFunction

;/********f* SeedUtil/IsKnownFood
* API VERSION ADDED
* 1
*
* DESCRIPTION
* Returns whether the item is a known food.
*
* SYNTAX
*/;
bool function IsKnownFood(Form akBaseObject) global
;/*
* PARAMETERS
* akBaseObject: The form to check.
*
* RETURN VALUE
* True if the form is food; false otherwise.
*
* EXAMPLES
;Is the squibble something I can eat?
bool is_food = SeedUtil.IsItemFood(squibble)
;*********/;
    LastSeedAPI LastSeed = GetAPI()
    if LastSeed == none
        RaiseSeedAPIError()
        return false
    endif

    ;@TODO
endFunction

;/********f* SeedUtil/RestorePlayerHunger
* API VERSION ADDED
* 1
*
* DESCRIPTION
* Restores the player's hunger by the provided amount.
*
* SYNTAX
*/;
function RestorePlayerHunger(float afAmount) global
;/*
* PARAMETERS
* afAmount: The amount to restore hunger by.
*
* RETURN VALUE
* None.
*
* EXAMPLES
;Restore the player's hunger up to the next level.
SeedUtil.RestorePlayerHunger(20.0)
;*********/;
    LastSeedAPI LastSeed = GetAPI()
    if LastSeed == none
        RaiseSeedAPIError()
        return
    endif

    LastSeed.Hunger.DecreaseAttribute(afAmount)
endFunction

;/********f* SeedUtil/GetPlayerHunger
* API VERSION ADDED
* 1
*
* DESCRIPTION
* Gets the player's current Hunger.
*
* SYNTAX
*/;
float function GetPlayerHunger() global
;/*
* PARAMETERS
* None.
*
* RETURN VALUE
* The player's current Hunger value.
*
* EXAMPLES
;How hungry is the player?
float hunger = SeedUtil.GetPlayerHunger()
;*********/;
    LastSeedAPI LastSeed = GetAPI()
    if LastSeed == none
        RaiseSeedAPIError()
        return -1.0
    endif

    return LastSeed.Hunger.attributeValueGlobal.GetValue()
endFunction

;/********f* SeedUtil/GetPlayerHungerLevel
* API VERSION ADDED
* 1
*
* DESCRIPTION
* Return the player's current hunger level. May be easier to use than GetPlayerHunger() if you don't
* need to know the actual hunger value.
*
* SYNTAX
*/;
int function GetPlayerHungerLevel() global
;/*
* PARAMETERS
* None
*
* RETURN VALUE
* * The player's current hunger level.
* * 0 = Well Fed
* * 1 = Satisfied
* * 2 = Hungry
* * 3 = Very Hungry
* * 4 = Ravenous
* * 5 = Starving
*
* EXAMPLES
;Is the player hungry?
float hng_level = SeedUtil.GetPlayerHungerLevel()
if hng_level >= 2
    debug.notification("Man I'm hungry!")
endif
;*********/;
    LastSeedAPI LastSeed = GetAPI()
    if LastSeed == none
        RaiseSeedAPIError()
        return -1
    endif

    return LastSeed._Seed_HungerLevel.GetValueInt()
endFunction

;/********f* SeedUtil/GetPlayerThirst
* API VERSION ADDED
* 1
*
* DESCRIPTION
* Gets the player's current Thirst.
*
* SYNTAX
*/;
float function GetPlayerThirst() global
;/*
* PARAMETERS
* None.
*
* RETURN VALUE
* The player's current Thirst value.
*
* EXAMPLES
;How thirsty is the player?
float thirst = SeedUtil.GetPlayerThirst()
;*********/;
    LastSeedAPI LastSeed = GetAPI()
    if LastSeed == none
        RaiseSeedAPIError()
        return -1.0
    endif

    return LastSeed.Thirst.attributeValueGlobal.GetValue()
endFunction

;/********f* SeedUtil/GetPlayerThirstLevel
* API VERSION ADDED
* 1
*
* DESCRIPTION
* Return the player's current thirst level. May be easier to use than GetPlayerThirst() if you don't
* need to know the actual thirst value.
*
* SYNTAX
*/;
int function GetPlayerThirstLevel() global
;/*
* PARAMETERS
* None
*
* RETURN VALUE
* * The player's current thirst level.
* * 0 = Quenched
* * 1 = Refreshed
* * 2 = Thirsty
* * 3 = Very Thirsty
* * 4 = Parched
* * 5 = Dehydrated
*
* EXAMPLES
;Is the player thirsty?
float thirst_level = SeedUtil.GetPlayerThirstLevel()
if thirst_level >= 2
    debug.notification("Man I'm thirsty!")
endif
;*********/;
    LastSeedAPI LastSeed = GetAPI()
    if LastSeed == none
        RaiseSeedAPIError()
        return -1
    endif

    return LastSeed._Seed_ThirstLevel.GetValueInt()
endFunction

;/********f* SeedUtil/GetPlayerFatigue
* API VERSION ADDED
* 1
*
* DESCRIPTION
* Gets the player's current Fatigue.
*
* SYNTAX
*/;
float function GetPlayerFatigue() global
;/*
* PARAMETERS
* None.
*
* RETURN VALUE
* The player's current Fatigue value.
*
* EXAMPLES
;How fatigued is the player?
float fatigue = SeedUtil.GetPlayerFatigue()
;*********/;
    LastSeedAPI LastSeed = GetAPI()
    if LastSeed == none
        RaiseSeedAPIError()
        return -1.0
    endif

    return LastSeed.Fatigue.attributeValueGlobal.GetValue()
endFunction

;/********f* SeedUtil/GetPlayerFatigueLevel
* API VERSION ADDED
* 1
*
* DESCRIPTION
* Return the player's current fatigue level. May be easier to use than GetPlayerFatigue() if you don't
* need to know the actual fatigue value.
*
* SYNTAX
*/;
int function GetPlayerFatigueLevel() global
;/*
* PARAMETERS
* None
*
* RETURN VALUE
* * The player's current fatigue level.
* * 0 = Rested / Well Rested / Lover's Comfort
* * 1 = Sharp
* * 2 = Tired
* * 3 = Very Tired
* * 4 = Haggard
* * 5 = Exhausted
*
* EXAMPLES
;Is the player tired?
float fatigue_level = SeedUtil.GetPlayerFatigueLevel()
if fatigue_level >= 2
    debug.notification("Man I'm tired!")
endif
;*********/;
    LastSeedAPI LastSeed = GetAPI()
    if LastSeed == none
        RaiseSeedAPIError()
        return -1
    endif

    return LastSeed._Seed_FatigueLevel.GetValueInt()
endFunction

;/********f* SeedUtil/GetPlayerVitality
* API VERSION ADDED
* 1
*
* DESCRIPTION
* Gets the player's current Vitality.
*
* SYNTAX
*/;
float function GetPlayerVitality() global
;/*
* PARAMETERS
* None.
*
* RETURN VALUE
* The player's current Vitality value.
*
* EXAMPLES
;How high is the player's Vitality?
float vitality = SeedUtil.GetPlayerVitality()
;*********/;
    LastSeedAPI LastSeed = GetAPI()
    if LastSeed == none
        RaiseSeedAPIError()
        return -1.0
    endif

    return LastSeed.Vitality.attributeValueGlobal.GetValue()
endFunction

;/********f* SeedUtil/GetPlayerVitalityLevel
* API VERSION ADDED
* 1
*
* DESCRIPTION
* Return the player's current vitality level. May be easier to use than GetPlayerVitality() if you don't
* need to know the actual vitality value.
*
* SYNTAX
*/;
int function GetPlayerVitalityLevel() global
;/*
* PARAMETERS
* None
*
* RETURN VALUE
* * The player's current vitality level.
* * 0 = Dying
* * 1 = Ruined
* * 2 = Weakened
* * 3 = Drained
* * 4 = Healthy
* * 5 = Very Healthy
* * 6 = Vigorous
* * 7 = Peak Condition
*
* NOTES
* Unlike other needs, higher vitality is better.
* 
* EXAMPLES
;Is the player healthy?
float vitality_level = SeedUtil.GetPlayerVitalityLevel()
if vitality_level >= 5
    debug.notification("I'm a health nut!")
endif
;*********/;
    LastSeedAPI LastSeed = GetAPI()
    if LastSeed == none
        RaiseSeedAPIError()
        return -1
    endif

    return LastSeed._Seed_VitalityLevel.GetValueInt()
endFunction

function RaiseSeedAPIError() global
    debug.trace("[LastSeed][ERROR] Fatal Last Seed API error occurred.")
endFunction























; =============================================================================
;
;
;
;
;            While on this glowing canvas stands
;            The labour of my busy hands
;            It will remain when I am gone
;            For you my friends to look upon
;
;
;
;
;==============================================================================