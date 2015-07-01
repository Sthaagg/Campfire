scriptname _Seed_SpoilSystem extends Quest

; To do:
;   Better positioning of in-world spoil objects and motion type (bug - dropped food doesn't report pos correctly)
;   Profile with many foods

import StringUtil
import CampUtil

Actor property PlayerRef auto
bool property initialized = false auto hidden
int property current_spoil_interval = 1 auto hidden
GlobalVariable property _Seed_DebugDumpFT auto
GlobalVariable property _Seed_DebugDumpST auto
GlobalVariable property _Seed_DebugDumpVerbose auto

float last_interval_timestamp

; TrackedFoodTable
Form[] TrackedFoodBaseObject_1
Form[] TrackedFoodBaseObject_2
int[] PerishableFoodID_1
int[] PerishableFoodID_2
int[] TrackedFoodCount_1
int[] TrackedFoodCount_2
int[] LastInterval_1
int[] LastInterval_2
ObjectReference[] Container_1
ObjectReference[] Container_2
ObjectReference[] TrackedFoodReference_1
ObjectReference[] TrackedFoodReference_2

int COL_FOOD_FORM = 100
int COL_PERISHABLEFOODID_FK = 101
int COL_FOOD_COUNT = 102
int COL_LAST_INTERVAL = 103
int COL_CONTAINER = 104
int COL_FOOD_REFERENCE = 105

; PerishableFoodTable
Form[] FoodSpoilStage1_1
Form[] FoodSpoilStage1_2
Form[] FoodSpoilStage2_1
Form[] FoodSpoilStage2_2
Form[] FoodSpoilStage3_1
Form[] FoodSpoilStage3_2
Form[] FoodSpoilStage4_1
Form[] FoodSpoilStage4_2
Int[] FoodSpoilRate_1
Int[] FoodSpoilRate_2

int COL_FOOD_SPOIL_STAGE1 = 200
int COL_FOOD_SPOIL_STAGE2 = 201
int COL_FOOD_SPOIL_STAGE3 = 202
int COL_FOOD_SPOIL_STAGE4 = 203
int COL_FOOD_SPOIL_RATE = 204

GlobalVariable property _Seed_SpoilSystemEnabled auto

; Spoil Rate = Spoil every x 3 hour intervals
GlobalVariable property _Seed_SpoilRate_RawMeat auto                ; 1
GlobalVariable property _Seed_SpoilRate_FruitVegetables auto        ; 12
GlobalVariable property _Seed_SpoilRate_Cheese auto                 ; 12
GlobalVariable property _Seed_SpoilRate_BreadSweets auto            ; 8
GlobalVariable property _Seed_SpoilRate_CookedFood auto             ; 4

float UPDATE_GAMETIME_RATE = 3.0

;@TODO: STARTUP SYSTEM
Event OnInit()
    Initialize()
    SetupData()
    RegisterForSingleUpdateGameTime(UPDATE_GAMETIME_RATE)
endEvent

Event OnUpdateGameTime()
    ; Look at this timestamp and old timestamp, determine how many rollups I should be doing
    float current_time = Utility.GetCurrentGameTime()
    int intervals = Math.Floor(((current_time - last_interval_timestamp) * 24.0) / 3)
    debug.trace("[Seed] intervals " + intervals)
    current_spoil_interval += intervals
    AdvanceSpoilage()
    last_interval_timestamp = current_time

    if _Seed_SpoilSystemEnabled.GetValueInt() == 2
        RegisterForSingleUpdateGameTime(UPDATE_GAMETIME_RATE)
    endif
endEvent

;@override
function SetupData()

endFunction

Function Initialize()
    TrackedFoodBaseObject_1 = new Form[128]
    TrackedFoodBaseObject_2 = new Form[128]
    PerishableFoodID_1 = new Int[128]
    PerishableFoodID_2 = new Int[128]
    TrackedFoodCount_1 = new Int[128]
    TrackedFoodCount_2 = new Int[128]
    LastInterval_1 = new Int[128]
    LastInterval_2 = new Int[128]
    Container_1 = new ObjectReference[128]
    Container_2 = new ObjectReference[128]
    TrackedFoodReference_1 = new ObjectReference[128]
    TrackedFoodReference_2 = new ObjectReference[128]

    FoodSpoilStage1_1 = new Form[128]
    FoodSpoilStage1_2 = new Form[128]
    FoodSpoilStage2_1 = new Form[128]
    FoodSpoilStage2_2 = new Form[128]
    FoodSpoilStage3_1 = new Form[128]
    FoodSpoilStage3_2 = new Form[128]
    FoodSpoilStage4_1 = new Form[128]
    FoodSpoilStage4_2 = new Form[128]
    FoodSpoilRate_1 = new Int[128]
    FoodSpoilRate_2 = new Int[128]
    initialized = true
endFunction

function AdvanceSpoilage()
    debug.trace("[Seed] Spoiling food...")
    int[] rows_to_remove = new int[128]
    int i = 0
    int size = TrackedFoodTable_FindAvailableIndex()
    if size == -1
        size = 256
    endif

    while i < size
        debug.trace("[Seed] Spoil loop " + i)
        int this_food_interval = TrackedFoodTable_GetIntervalAtIndex(i)
        int this_food_count = TrackedFoodTable_GetCountAtIndex(i)
        int this_food_perishid = TrackedFoodTable_GetPerishIDAtIndex(i)

        if this_food_interval == 0 || this_food_count == 0
            debug.trace("[Seed] this row has no interval or count, but is populated.")
            ; Sanity check; this row has no interval or count, but is populated.
            ArrayAddInt(rows_to_remove, i + 1000)
        
        elseif (current_spoil_interval - this_food_interval) >= GetSpoilRateByIndex(this_food_perishid)
            debug.trace("[Seed] Spoil rate exceeded for food " + i)
            ; Spoil the food
            Form this_food = TrackedFoodTable_GetFoodFormAtIndex(i)
            debug.trace("[Seed] This spoiled stage form: " + this_food.GetName())
            ObjectReference this_food_ref = TrackedFoodTable_GetRefAtIndex(i)
            ObjectReference this_food_container = TrackedFoodTable_GetContainerAtIndex(i)
            
            Form spoiled_food = GetNextSpoilStageForm(this_food, this_food_perishid)
            debug.trace("[Seed] Next spoiled stage form: " + spoiled_food.GetName())
            if spoiled_food == None
                debug.trace("[Seed] Already completely spoiled.")
                ; Already completely spoiled, stop tracking.
                ArrayAddInt(rows_to_remove, i + 1000)

            elseif this_food_ref != None && this_food_container == None
                debug.trace("[Seed] Attempting to spoil food in the world.")
                ObjectReference spoiled_food_ref = SpoilFoodInWorld(this_food_ref, spoiled_food)
                TrackedFoodTable_UpdateRow(i, akFood = spoiled_food, aiNewLastInterval = current_spoil_interval, akFoodRef = spoiled_food_ref)

            elseif this_food_container != None
                debug.trace("[Seed] Attempting to spoil food in a container.")
                SpoilFoodInContainer(this_food, spoiled_food, this_food_container, this_food_count)
                if !IsEventSendingActor(this_food_container)
                    TrackedFoodTable_UpdateRow(i, akFood = spoiled_food, aiNewLastInterval = current_spoil_interval)    
                else
                    debug.trace("[Seed] This container is an event-sending actor; avoiding manual row update.")
                endif
            else
                debug.trace("[Seed] Sanity check; has no ref or container, so stop tracking.")
                ; Sanity check; has no ref or container, so stop tracking.
                ArrayAddInt(rows_to_remove, i + 1000)
            endif
        endif
        i += 1
    endWhile

    ; remove rows tagged for removal and resort
    int rsize = rows_to_remove.Find(0)
    if rsize > 0
        int k = 0
        while k < rsize
            TrackedFoodTable_RemoveRow(rows_to_remove[k] - 1000)
            k += 1
        endWhile
        debug.trace("[Seed] Sorting because rows removed as part of spoil process.")
        TrackedFoodTable_SortByOldest()
    endif
endFunction

bool function IsEventSendingActor(ObjectReference akReference)
    if (akReference as actor) && (akReference == PlayerRef || akReference == GetTrackedFollower(1) || \
                                  akReference == GetTrackedFollower(2) || akReference == GetTrackedFollower(3))
        return true
    else
        return false
    endif
endFunction

function SpoilFoodInContainer(Form akFood, Form akSpoiledFood, ObjectReference akContainer, int aiCount)
    akContainer.RemoveItem(akFood, aiCount, true)
    utility.wait(0.1)
    akContainer.AddItem(akSpoiledFood, aiCount, true)
endFunction

ObjectReference function SpoilFoodInWorld(ObjectReference akFoodRef, Form akSpoiledFood)
    akFoodRef.Disable()
    ObjectReference ref = akFoodRef.PlaceAtMe(akSpoiledFood, 1)
    int i = 0
    while !ref.Is3DLoaded() || i > 50
        i += 1
    endWhile
    ref.SetMotionType(4)
    ref.MoveTo(akFoodRef)
    akFoodRef.Delete()
    return ref
endFunction

function HandleFoodConsumed(Form akFood, ObjectReference akConsumer, int aiCount)
    bool found_tracked_food = false
    int[] found_indicies

    found_indicies = FindTrackedFoodsByContainer(akFood, akConsumer)
    if found_indicies[0] != 0
        debug.trace("[Seed] (HandleFoodConsumed) Already tracking this food at indicies " + found_indicies[0] + ", " + found_indicies[1] + ", " + found_indicies[2] + "...")
        found_tracked_food = true
    endif

    if found_tracked_food
        ; Determine the total number of currently tracked foods that match the criteria.
        int tracked_count = 0
        bool sort_required = false
        int i = 0
        bool break = false
        while i < found_indicies.Length && !break
            if found_indicies[i] != 0
                tracked_count += BigArrayGetIntAtIndex_Do(found_indicies[i] - 1000, TrackedFoodCount_1, TrackedFoodCount_2)
                i += 1
            else
                break = true
            endif
        endWhile

        int remaining_to_remove = aiCount
        int j = 0
        int size = found_indicies.Find(0)
        if size == -1
            size = 128
        endif

        while (remaining_to_remove > 0 && j < size)
            debug.trace("[Seed] remaining_to_remove = " + remaining_to_remove + ", j = " + j)
            int entry_count = BigArrayGetIntAtIndex_Do(found_indicies[j] - 1000, TrackedFoodCount_1, TrackedFoodCount_2)
            if entry_count <= remaining_to_remove
                ; Remove entry
                TrackedFoodTable_RemoveRow(found_indicies[j] - 1000)
                remaining_to_remove -= entry_count
                sort_required = true
            else
                ; Subtract transferred amount from existing entry, and add new entry for partial transfer, maintaining the entry interval
                TrackedFoodTable_UpdateRow(found_indicies[j] - 1000, aiCount = (entry_count - remaining_to_remove))
                remaining_to_remove = 0
                sort_required = true
            endif
            j += 1
        endWhile
        debug.trace("[Seed] Exited consumption deduction loop.")

        if sort_required
            debug.trace("[Seed] Sorting required after consumption because rows were removed or modified.")
            TrackedFoodTable_SortByOldest()
        endif
    endif
endFunction

function HandleFoodTransferToContainer(Form akFood, int aiXferredCount, ObjectReference akOldContainer, ObjectReference akNewContainer, ObjectReference akOldRef)
    ; Handle food moving between containers, or from the world to a container.

    debug.trace("[Seed] HandleFoodTransferToContainer")
    bool found_tracked_food = false
    int[] found_indicies
    
    ; Is this food already in the table?
    if akOldRef
        found_indicies = FindTrackedFoodsByRef(akOldRef)
        if found_indicies[0] != 0
            found_tracked_food = true
        endif
    endif
    
    if !found_tracked_food && akOldContainer
        found_indicies = FindTrackedFoodsByContainer(akFood, akOldContainer)
        if found_indicies[0] != 0
            found_tracked_food = true
        endif
    endif

    if found_tracked_food
        bool sort_required = false

        ; Transfer the items by updating their rows and adding new ones as required.        
        int criteria_match_count = GetIntDataSetSize(found_indicies)
        int remaining_to_transfer = aiXferredCount

        int j = 0
        while (remaining_to_transfer > 0 && j < criteria_match_count)
            int entry_count = BigArrayGetIntAtIndex_Do(found_indicies[j] - 1000, TrackedFoodCount_1, TrackedFoodCount_2)
            if entry_count <= remaining_to_transfer
                ; Transfer location in place
                TrackedFoodTable_UpdateRow(found_indicies[j] - 1000, akContainer = akNewContainer, akFoodRef = akNewRef, clear_container = (akNewContainer==None), clear_ref = (akNewRef==None))
                remaining_to_transfer -= entry_count
            else
                ; Subtract transferred amount from existing entry, and add new entry for partial transfer, maintaining the entry interval
                TrackedFoodTable_UpdateRow(found_indicies[j] - 1000, aiCount = (entry_count - remaining_to_transfer))
                int interval = BigArrayGetIntAtIndex_Do(found_indicies[j] - 1000, LastInterval_1, LastInterval_2)
                AddTrackedFood(akFood, remaining_to_transfer, akNewContainer, akNewRef, interval)
                remaining_to_transfer = 0
                sort_required = true
            endif
            j += 1
        endWhile

        ; If there were more transferred than we were tracking, add new entries for those items
        if remaining_to_transfer > 0
            AddTrackedFood(akFood, remaining_to_transfer, akNewContainer, akNewRef)
        endif

        if sort_required
            debug.trace("[Seed] Sorting required after transfer because rows were removed or modified.")
            TrackedFoodTable_SortByOldest()
        endif
    else
        ; Not tracking this food object, so create a table entry
        AddTrackedFood(akFood, aiXferredCount, akNewContainer, akNewRef)
    endif
endFunction

function HandleFoodTransferToWorld(Form akFood, ObjectReference akOldContainer, ObjectReference[] akNewRefs)
    ; Handle food moving from a container to the world. Assumes a set of individual references (not a stack).

    debug.trace("[Seed] HandleFoodTransferToWorld")
    bool found_tracked_food = false
    int[] found_indicies
    
    ; Is this food already in the table?
    found_indicies = FindTrackedFoodsByContainer(akFood, akOldContainer)
    if found_indicies[0] != 0
        found_tracked_food = true
    endif

    if found_tracked_food
        bool sort_required = false

        ; Transfer the items by updating their rows and adding new ones as required.
        int criteria_match_count = GetIntDataSetSize(found_indicies)
        int refs_to_transfer = GetRefDataSetSize(akNewRefs)

        int j = 0
        int k = 0
        int food_transferred = 0
        break = false
        while (j < refs_to_transfer)    ;for ref in refset
            while (k < criteria_match_count && !break)    ;for match in matchset
                int entry_count = BigArrayGetIntAtIndex_Do(found_indicies[k] - 1000, TrackedFoodCount_1, TrackedFoodCount_2)
                if entry_count > 1
                    ; subtract from existing entry and add new tracked reference
                    TrackedFoodTable_UpdateRow(found_indicies[k] - 1000, aiCount = entry_count - 1)
                    TrackedFoodTable_AddRow(akFood, 1, TrackedFoodTable_GetIntervalAtIndex(found_indicies[k] - 1000), None, akNewRefs[j])
                    food_transferred += 1
                    sort_required = true
                    break = true
                elseif entry_count == 1
                    ; update this record in place
                    TrackedFoodTable_UpdateRow(found_indicies[k] - 1000, akFoodRef = akNewRefs[j], clear_container = true)
                    food_transferred += 1
                    ; we've exhausted this record, increment to the next existing match
                    k += 1
                    break = true
                else
                    ; Error, we shouldn't ever have rows with 0 count. Force a consistency check later.
                    k += 1
                endif
            endWhile

            break = false
            j += 1
        endWhile

        ; If there were more transferred than we were tracking, add new entries for those items
        while food_transferred < refs_to_transfer
            AddTrackedFood(akFood, 1, None, akNewRefs[food_transferred])
            food_transferred += 1
        endif

        if sort_required
            debug.trace("[Seed] Sorting required after transfer because rows were removed or modified.")
            TrackedFoodTable_SortByOldest()
        endif
    else
        ; Not tracking these food objects, so create table entries
        int refs_to_transfer = GetRefDataSetSize(akNewRefs)
        int food_transferred = 0
        while food_transferred < refs_to_transfer
            AddTrackedFood(akFood, 1, None, akNewRefs[food_transferred])
            food_transferred += 1
        endif
    endif
endFunction

int function GetIntDataSetSize(int[] array)
    int size = array.Find(0)
    if size == -1
        size = 128
    endif
    return size
endFunction

int function GetRefDataSetSize(ObjectReference[] array)
    int size = array.Find(None)
    if size == -1
        size = 128
    endif
    return size
endFunction

function AddTrackedFood(Form akFood, int aiCount, ObjectReference akContainer, ObjectReference akFoodRef, int aiInterval = 0)
    debug.trace("[Seed] AddTrackedFood")
    if aiInterval == 0
        aiInterval = current_spoil_interval
    endif
    TrackedFoodTable_AddRow(akFood, aiCount, aiInterval, akContainer, akFoodRef)
endFunction 

int[] function FindTrackedFoodsByRef(ObjectReference akFoodRef)
    int[] indicies = new Int[128]
    int found_index = -1
    found_index = BigArrayFindRef_Do(akFoodRef, TrackedFoodReference_1, TrackedFoodReference_2)
    if found_index != -1
        indicies[0] = found_index + 1000
        int i = 0
        while found_index != -1 && i < indicies.Length
            found_index = BigArrayFindNextRef_Do(akFoodRef, TrackedFoodReference_1, TrackedFoodReference_2, found_index + 1)
            if found_index != -1
                indicies[i] = found_index + 1000
            endif
            i += 1
        endWhile
    endif
    return indicies
endFunction

int function FindOldestTrackedFoodByContainer(Form akFood, ObjectReference akContainer)
    int found_index = -1
    found_index = BigArrayFindRef_Do(akContainer, Container_1, Container_2)
    if found_index != -1
        if BigArrayGetFormAtIndex_Do(found_index, TrackedFoodBaseObject_1, TrackedFoodBaseObject_2) == akFood
            return found_index
        else
            while found_index != -1
                found_index = BigArrayFindNextRef_Do(akContainer, Container_1, Container_2, found_index + 1)
                if found_index != -1
                    if BigArrayGetFormAtIndex_Do(found_index, TrackedFoodBaseObject_1, TrackedFoodBaseObject_2) == akFood
                        return found_index
                    endif
                endif
            endWhile
        endif
    endif
    return -1
endFunction

int[] function FindTrackedFoodsByContainer(Form akFood, ObjectReference akContainer)
    int[] indicies = new Int[128]
    int current_index = -1
    current_index = BigArrayFindRef_Do(akContainer, Container_1, Container_2)
    if current_index != -1
        if BigArrayGetFormAtIndex_Do(current_index, TrackedFoodBaseObject_1, TrackedFoodBaseObject_2) == akFood
            indicies[0] = current_index + 1000
        endif
        int i = 0
        while current_index != -1 && i < indicies.Length
            current_index = BigArrayFindNextRef_Do(akContainer, Container_1, Container_2, current_index + 1)
            if current_index != -1
                if BigArrayGetFormAtIndex_Do(current_index, TrackedFoodBaseObject_1, TrackedFoodBaseObject_2) == akFood
                    indicies[i] = current_index + 1000
                endif
            endif
            i += 1
        endWhile
    endif
    return indicies
endFunction

; SPOILAGE HELPER FUNCTIONS

Form function GetNextSpoilStageForm(Form akBaseObject, int aiPerishableFoodID)
    int index
    string food_name = akBaseObject.GetName()
    if HasSpoilStage4Name(food_name)
        return None
    elseif HasSpoilStage3Name(food_name)
        return BigArrayGetFormAtIndex_Do(aiPerishableFoodID, FoodSpoilStage4_1, FoodSpoilStage4_2)
    elseif HasSpoilStage2Name(food_name)
        return BigArrayGetFormAtIndex_Do(aiPerishableFoodID, FoodSpoilStage3_1, FoodSpoilStage3_2)
    else
        return BigArrayGetFormAtIndex_Do(aiPerishableFoodID, FoodSpoilStage2_1, FoodSpoilStage2_2)
    endif
endFunction

Int function GetSpoilRateByForm(Form akBaseObject)
    int index
    string food_name = akBaseObject.GetName()
    if HasSpoilStage4Name(food_name)
        index = PerishableFoodTable_FindFormInColumn(akBaseObject, COL_FOOD_SPOIL_STAGE4)
        if index != -1
            return GetSpoilRateByIndex(index)
        endif
    elseif HasSpoilStage3Name(food_name)
        index = PerishableFoodTable_FindFormInColumn(akBaseObject, COL_FOOD_SPOIL_STAGE3)
        if index != -1
            return GetSpoilRateByIndex(index)
        endif
    elseif HasSpoilStage2Name(food_name)
        index = PerishableFoodTable_FindFormInColumn(akBaseObject, COL_FOOD_SPOIL_STAGE2)
        if index != -1
            return GetSpoilRateByIndex(index)
        endif
    else
        index = PerishableFoodTable_FindFormInColumn(akBaseObject, COL_FOOD_SPOIL_STAGE1)
        if index != -1
            return GetSpoilRateByIndex(index)
        endif
    endif
    return -1
endFunction

int function GetSpoilRateByIndex(int index)
    debug.trace("[Seed] Returning spoil rate " + BigArrayGetIntAtIndex_Do(index, FoodSpoilRate_1, FoodSpoilRate_2))
    return BigArrayGetIntAtIndex_Do(index, FoodSpoilRate_1, FoodSpoilRate_2)
endFunction

Int function GetPerishableFoodIndex(Form akBaseObject)
    int index
    string food_name = akBaseObject.GetName()
    if HasSpoilStage4Name(food_name)
        index = PerishableFoodTable_FindFormInColumn(akBaseObject, COL_FOOD_SPOIL_STAGE4)
        if index != -1
            return index
        endif
    elseif HasSpoilStage3Name(food_name)
        index = PerishableFoodTable_FindFormInColumn(akBaseObject, COL_FOOD_SPOIL_STAGE3)
        if index != -1
            return index
        endif
    elseif HasSpoilStage2Name(food_name)
        index = PerishableFoodTable_FindFormInColumn(akBaseObject, COL_FOOD_SPOIL_STAGE2)
        if index != -1
            return index
        endif
    else
        index = PerishableFoodTable_FindFormInColumn(akBaseObject, COL_FOOD_SPOIL_STAGE1)
        if index != -1
            return index
        endif
    endif
    return -1
endFunction

bool function HasSpoilStage4Name(string asFoodName)
    if Find(asFoodName, "Rotten") != -1 || Find(asFoodName, "Rancid") != -1 || Find(asFoodName, "Foul") != -1 
        return true
    else
        return false
    endif
endFunction

bool function HasSpoilStage3Name(string asFoodName)
    if Find(asFoodName, "Spoiled") != -1 || Find(asFoodName, "Moldy") != -1
        return true
    else
        return false
    endif
endFunction

bool function HasSpoilStage2Name(string asFoodName)
    if Find(asFoodName, "Stale") != -1 || Find(asFoodName, "Overripe") != -1 || \
        Find(asFoodName, "Dry") != -1 || Find(asFoodName, "Old") != -1
        return true
    else
        return false
    endif
endFunction


; TABLE FUNCTIONS

; PerishableFoodTable
; FoodSpoilStage1 | FoodSpoilStage2 | FoodSpoilStage3 | FoodSpoilStage4 | SpoilRate |
; ================|=================|=================|=================|===========|
; Bread           | Old Bread       | Moldy Bread     | Foul Bread      | 6         |

int function PerishableFoodTable_AddRow(Form food_stage1, Form food_stage2, Form food_stage3, Form food_stage4, int rate, int cursor = -1)
    if cursor == -1
        cursor = PerishableFoodTable_FindAvailableIndex()
        if cursor == -1
            ;@TODO: Log error
            return -1
        endif
    endif
    PerishableFoodTable_BigArrayAdd(COL_FOOD_SPOIL_STAGE1, cursor, akBaseObject = food_stage1)
    PerishableFoodTable_BigArrayAdd(COL_FOOD_SPOIL_STAGE2, cursor, akBaseObject = food_stage2)
    PerishableFoodTable_BigArrayAdd(COL_FOOD_SPOIL_STAGE3, cursor, akBaseObject = food_stage3)
    PerishableFoodTable_BigArrayAdd(COL_FOOD_SPOIL_STAGE4, cursor, akBaseObject = food_stage4)
    PerishableFoodTable_BigArrayAdd(COL_FOOD_SPOIL_RATE, cursor, aiValue = rate)
    PerishableFoodTable_DebugPrintTable()
    return cursor
endFunction

int function PerishableFoodTable_FindFormInColumn(Form akBaseObject, int BigArrayID)
    if BigArrayID == COL_FOOD_SPOIL_STAGE1
        return BigArrayFindForm_Do(akBaseObject, FoodSpoilStage1_1, FoodSpoilStage1_2)
    elseif BigArrayID == COL_FOOD_SPOIL_STAGE2
        return BigArrayFindForm_Do(akBaseObject, FoodSpoilStage2_1, FoodSpoilStage2_2)
    elseif BigArrayID == COL_FOOD_SPOIL_STAGE3
        return BigArrayFindForm_Do(akBaseObject, FoodSpoilStage3_1, FoodSpoilStage3_2)
    elseif BigArrayID == COL_FOOD_SPOIL_STAGE4
        return BigArrayFindForm_Do(akBaseObject, FoodSpoilStage4_1, FoodSpoilStage4_2)
    endif
endFunction

Form function PerishableFoodTable_GetFoodAtIndexColumn(int index, int col)
    if col == COL_FOOD_SPOIL_STAGE1
        return BigArrayGetFormAtIndex_Do(index, FoodSpoilStage1_1, FoodSpoilStage1_2)
    elseif col == COL_FOOD_SPOIL_STAGE2
        return BigArrayGetFormAtIndex_Do(index, FoodSpoilStage2_1, FoodSpoilStage2_2)
    elseif col == COL_FOOD_SPOIL_STAGE3
        return BigArrayGetFormAtIndex_Do(index, FoodSpoilStage3_1, FoodSpoilStage3_2)
    elseif col == COL_FOOD_SPOIL_STAGE4
        return BigArrayGetFormAtIndex_Do(index, FoodSpoilStage4_1, FoodSpoilStage4_2)
    endif
endFunction

int function PerishableFoodTable_FindAvailableIndex()
    return BigArrayFindForm_Do(None, FoodSpoilStage1_1, FoodSpoilStage1_2)
endFunction

function PerishableFoodTable_DebugPrintTable()
    debug.trace("[Seed] PerishableFoodTable")
    debug.trace("[Seed] =====================================================================================================================")
    debug.trace("[Seed] | Idx |   FoodSpoilStage1   |    FoodSpoilStage2   |    FoodSpoilStage3   |    FoodSpoilStage4   |     SpoilRate    |")
    int i = 0
    bool break = false
    while i < 255
        break = PerishableFoodTable_DebugPrintRow(i)
        i += 1
    endWhile
endFunction

bool function PerishableFoodTable_DebugPrintRow(int index)
    if BigArrayGetFormAtIndex_Do(index, FoodSpoilStage1_1, FoodSpoilStage1_2) == None
        if _Seed_DebugDumpVerbose.GetValueInt() == 2
            ; continue
        else
            return true
        endif
    endif
    string stage_1_name
    string stage_2_name
    string stage_3_name
    string stage_4_name

    Form f1 = BigArrayGetFormAtIndex_Do(index, FoodSpoilStage1_1, FoodSpoilStage1_2)
    Form f2 = BigArrayGetFormAtIndex_Do(index, FoodSpoilStage2_1, FoodSpoilStage2_2)
    Form f3 = BigArrayGetFormAtIndex_Do(index, FoodSpoilStage3_1, FoodSpoilStage3_2)
    Form f4 = BigArrayGetFormAtIndex_Do(index, FoodSpoilStage4_1, FoodSpoilStage4_2)
    if f1
        stage_1_name = f1.GetName()
    endif
     if f2
        stage_2_name = f2.GetName()
    endif
     if f3
        stage_3_name = f3.GetName()
    endif
     if f4
        stage_4_name = f4.GetName()
    endif
    int spoil_rate = BigArrayGetIntAtIndex_Do(index, FoodSpoilRate_1, FoodSpoilRate_2)
    debug.trace("[Seed] | " + index + " | " + stage_1_name + " | " + stage_2_name + " | " + stage_3_name + " | " + stage_4_name + " | " + spoil_rate + " |")
    return false
endFunction

; TrackedFoodTable
; akBaseObject    | PerishableFoodID (FK) | Count | Last Interval | Container  | Reference  |
; ================|=======================|=======|===============|============|============|
; FoodApple       | 0                     | 3     | 316           | None       | 0xFF000011 |
; FoodCabbage     | 9                     | 1     | 474           | 0x0105674b | None       |
; FoodUnknown     | -1                    | 4     | 525           | 0x0000000f | None       |

function TrackedFoodTable_AddRow(Form akFood, int aiCount, int aiLastInterval, ObjectReference akContainer, ObjectReference akFoodRef)
    debug.trace("[Seed] TrackedFoodTable_AddRow")
    int index = TrackedFoodTable_FindAvailableIndex()
    if index == -1
        ;@TODO: Log error
        return
    endif
    int perish_index = GetPerishableFoodIndex(akFood)
    if perish_index == -1
        return
    endif
    debug.trace("[Seed] perish_index " + perish_index)
    TrackedFoodTable_BigArrayAdd(COL_FOOD_FORM, index, akBaseObject = akFood)
    TrackedFoodTable_BigArrayAdd(COL_PERISHABLEFOODID_FK, index, aiValue = perish_index)
    TrackedFoodTable_BigArrayAdd(COL_FOOD_COUNT, index, aiValue = aiCount)
    TrackedFoodTable_BigArrayAdd(COL_LAST_INTERVAL, index, aiValue = aiLastInterval)
    TrackedFoodTable_BigArrayAdd(COL_CONTAINER, index, akReference = akContainer)
    TrackedFoodTable_BigArrayAdd(COL_FOOD_REFERENCE, index, akReference = akFoodRef)
    TrackedFoodTable_DebugPrintTable()
endFunction

function TrackedFoodTable_UpdateRow(int index, Form akFood = None, int aiPerishableFoodID = -1, int aiCount = -1, int aiNewLastInterval = -1, ObjectReference akContainer = None, ObjectReference akFoodRef = None, bool clear_container = false, bool clear_ref = false)
    debug.trace("[Seed] TrackedFoodTable_UpdateRow(index=" + index + ", akFood=" + akFood + ", aiPerishableFoodID=" + aiPerishableFoodID + ", aiCount=" + aiCount + ", aiNewLastInterval=" + aiNewLastInterval + ", akContainer=" + akContainer + ", akFoodRef=" + akFoodRef + ", clear_container=" + clear_container + ", clear_ref=" + clear_ref)
    if akFood
        BigArrayAddForm_Do(index, akFood, TrackedFoodBaseObject_1, TrackedFoodBaseObject_2)
    endif
    if aiPerishableFoodID != -1
        BigArrayAddInt_Do(index, aiPerishableFoodID, PerishableFoodID_1, PerishableFoodID_2)
    endif
    if aiCount != -1
        BigArrayAddInt_Do(index, aiCount, TrackedFoodCount_1, TrackedFoodCount_2)
    endif
    if aiNewLastInterval != -1
        BigArrayAddInt_Do(index, aiNewLastInterval, LastInterval_1, LastInterval_2)
    endif
    if akContainer || clear_container
        BigArrayAddRef_Do(index, akContainer, Container_1, Container_2)
    endif
    if akFoodRef || clear_ref
        BigArrayAddRef_Do(index, akFoodRef, TrackedFoodReference_1, TrackedFoodReference_2)
    endif
    TrackedFoodTable_DebugPrintTable()
endFunction

function TrackedFoodTable_RemoveRow(int index)
    BigArrayClearForm_Do(index, TrackedFoodBaseObject_1, TrackedFoodBaseObject_2)
    BigArrayClearInt_Do(index, PerishableFoodID_1, PerishableFoodID_2)
    BigArrayClearInt_Do(index, TrackedFoodCount_1, TrackedFoodCount_2)
    BigArrayClearInt_Do(index, LastInterval_1, LastInterval_2)
    BigArrayClearRef_Do(index, Container_1, Container_2)
    BigArrayClearRef_Do(index, TrackedFoodReference_1, TrackedFoodReference_2)
    TrackedFoodTable_DebugPrintTable()
endFunction

function TrackedFoodTable_SortByOldest()
    debug.trace("[Seed] Beginning TrackedFoodTable sort.")
    ;From https://en.wikipedia.org/wiki/Selection_sort, converted to Papyrus
    int i
    int j = 0
    int iMin
    int n = BigArrayFindInt_Do(0, LastInterval_1, LastInterval_2)
    if n == -1
        n = 256
    endif
    while j < n - 1
        iMin = j
        i = j + 1
        while i < n
            int i_val = BigArrayGetIntAtIndex_Do(i, LastInterval_1, LastInterval_2)
            int iMin_val = BigArrayGetIntAtIndex_Do(iMin, LastInterval_1, LastInterval_2)
            if i_val > 0 && iMin_val == 0
                debug.trace("[Seed] [Sort] New min " + i + " (was " + iMin + ")")
                iMin = i
            elseif i_val < iMin_val
                debug.trace("[Seed] [Sort] New min " + i + " (was " + iMin + ")")
                iMin = i
            endif
            i += 1
        endWhile
        if iMin != j
            ; Get row j values
            Form temp_food = BigArrayGetFormAtIndex_Do(j, TrackedFoodBaseObject_1, TrackedFoodBaseObject_2)
            int temp_perishablefoodid = BigArrayGetIntAtIndex_Do(j, PerishableFoodID_1, PerishableFoodID_2)
            int temp_count = BigArrayGetIntAtIndex_Do(j, TrackedFoodCount_1, TrackedFoodCount_2)
            int temp_lastinterval = BigArrayGetIntAtIndex_Do(j, LastInterval_1, LastInterval_2)
            ObjectReference temp_container = BigArrayGetRefAtIndex_Do(j, Container_1, Container_2)
            ObjectReference temp_reference = BigArrayGetRefAtIndex_Do(j, TrackedFoodReference_1, TrackedFoodReference_2)

            ; Get row iMin values
            Form min_food = BigArrayGetFormAtIndex_Do(iMin, TrackedFoodBaseObject_1, TrackedFoodBaseObject_2)
            int min_perishablefoodid = BigArrayGetIntAtIndex_Do(iMin, PerishableFoodID_1, PerishableFoodID_2)
            int min_count = BigArrayGetIntAtIndex_Do(iMin, TrackedFoodCount_1, TrackedFoodCount_2)
            int min_lastinterval = BigArrayGetIntAtIndex_Do(iMin, LastInterval_1, LastInterval_2)
            ObjectReference min_container = BigArrayGetRefAtIndex_Do(iMin, Container_1, Container_2)
            ObjectReference min_reference = BigArrayGetRefAtIndex_Do(iMin, TrackedFoodReference_1, TrackedFoodReference_2)

            ; Swap row j values with row iMin values
            TrackedFoodTable_UpdateRow(j, min_food, min_perishablefoodid, min_count, min_lastinterval, min_container, min_reference)
            TrackedFoodTable_UpdateRow(iMin, temp_food, temp_perishablefoodid, temp_count, temp_lastinterval, temp_container, temp_reference)
        endif
        j += 1
    endWhile
    debug.trace("[Seed] TrackedFoodTable sort complete.")
    TrackedFoodTable_DebugPrintTable()
endFunction

Form function TrackedFoodTable_GetFoodFormAtIndex(int index)
    return BigArrayGetFormAtIndex_Do(index, TrackedFoodBaseObject_1, TrackedFoodBaseObject_2)
endFunction

int function TrackedFoodTable_GetIntervalAtIndex(int index)
    return BigArrayGetIntAtIndex_Do(index, LastInterval_1, LastInterval_2)
endFunction

int function TrackedFoodTable_GetCountAtIndex(int index)
    return BigArrayGetIntAtIndex_Do(index, TrackedFoodCount_1, TrackedFoodCount_2)
endFunction

ObjectReference function TrackedFoodTable_GetRefAtIndex(int index)
    return BigArrayGetRefAtIndex_Do(index, TrackedFoodReference_1, TrackedFoodReference_2)
endFunction

ObjectReference function TrackedFoodTable_GetContainerAtIndex(int index)
    return BigArrayGetRefAtIndex_Do(index, Container_1, Container_2)
endFunction

int function TrackedFoodTable_GetPerishIDAtIndex(int index)
    return BigArrayGetIntAtIndex_Do(index, PerishableFoodID_1, PerishableFoodID_2)
endFunction

int function TrackedFoodTable_FindAvailableIndex()
    return BigArrayFindForm_Do(None, TrackedFoodBaseObject_1, TrackedFoodBaseObject_2)
endFunction

function TrackedFoodTable_DebugPrintTable()
    debug.trace("[Seed] TrackedFoodTable")
    debug.trace("[Seed] =============================================================================================================")
    debug.trace("[Seed] | Idx |       akFood       |  PerishableFoodID(FK)  | Count | Last Interval | Container |     Reference     |")
    int i = 0
    bool break = false
    while i < 255 && !break
        break = TrackedFoodTable_DebugPrintRow(i)
        i += 1
    endWhile
    debug.trace("[Seed] [END OF TABLE]")
endFunction

bool function TrackedFoodTable_DebugPrintRow(int index)
    if BigArrayGetFormAtIndex_Do(index, TrackedFoodBaseObject_1, TrackedFoodBaseObject_2) == None
        if _Seed_DebugDumpVerbose.GetValueInt() == 2
            ; continue
        else
            return true
        endif
    endif
    string food_name
    Form f1 = BigArrayGetFormAtIndex_Do(index, TrackedFoodBaseObject_1, TrackedFoodBaseObject_2)
    if f1
        food_name = f1.GetName()
    endif
    int perishable_id = BigArrayGetIntAtIndex_Do(index, PerishableFoodID_1, PerishableFoodID_2)
    int food_count = BigArrayGetIntAtIndex_Do(index, TrackedFoodCount_1, TrackedFoodCount_2)
    int last_interval = BigArrayGetIntAtIndex_Do(index, LastInterval_1, LastInterval_2)
    ObjectReference container_ref = BigArrayGetRefAtIndex_Do(index, Container_1, Container_2)
    ObjectReference food_ref = BigArrayGetRefAtIndex_Do(index, TrackedFoodReference_1, TrackedFoodReference_2)
    debug.trace("[Seed] | " + index + " | " + food_name + " | " + perishable_id + " | " + food_count + " | " + last_interval + " | " + container_ref + " | " + food_ref + " |")
    return false
endFunction

; BIG ARRAY FUNCTIONS

function PerishableFoodTable_BigArrayAdd(int BigArrayID, int index, Form akBaseObject = None, Int aiValue = 0)
    if BigArrayID == COL_FOOD_SPOIL_STAGE1
        BigArrayAddForm_Do(index, akBaseObject, FoodSpoilStage1_1, FoodSpoilStage1_2)
    elseif BigArrayID == COL_FOOD_SPOIL_STAGE2
        BigArrayAddForm_Do(index, akBaseObject, FoodSpoilStage2_1, FoodSpoilStage2_2)
    elseif BigArrayID == COL_FOOD_SPOIL_STAGE3
        BigArrayAddForm_Do(index, akBaseObject, FoodSpoilStage3_1, FoodSpoilStage3_2)
    elseif BigArrayID == COL_FOOD_SPOIL_STAGE4
        BigArrayAddForm_Do(index, akBaseObject, FoodSpoilStage4_1, FoodSpoilStage4_2)
    elseif BigArrayID == COL_FOOD_SPOIL_RATE
        BigArrayAddInt_Do(index, aiValue, FoodSpoilRate_1, FoodSpoilRate_2)
    endif
endFunction

function TrackedFoodTable_BigArrayAdd(int BigArrayID, int index, Form akBaseObject = None, int aiValue = -1, ObjectReference akReference = None)
    if BigArrayID == COL_FOOD_FORM
        BigArrayAddForm_Do(index, akBaseObject, TrackedFoodBaseObject_1, TrackedFoodBaseObject_2)
    elseif BigArrayID == COL_PERISHABLEFOODID_FK
        BigArrayAddInt_Do(index, aiValue, PerishableFoodID_1, PerishableFoodID_2)
    elseif BigArrayID == COL_FOOD_COUNT
        BigArrayAddInt_Do(index, aiValue, TrackedFoodCount_1, TrackedFoodCount_2)
    elseif BigArrayID == COL_LAST_INTERVAL
        BigArrayAddInt_Do(index, aiValue, LastInterval_1, LastInterval_2)
    elseif BigArrayID == COL_CONTAINER
        BigArrayAddRef_Do(index, akReference, Container_1, Container_2)
    elseif BigArrayID == COL_FOOD_REFERENCE
        BigArrayAddRef_Do(index, akReference, TrackedFoodReference_1, TrackedFoodReference_2)
    endif
endFunction

int function BigArrayFindForm_Do(Form akBaseObject, Form[] array1, Form[] array2)
    int index = array1.Find(akBaseObject)
    if index == -1
        index = array2.Find(akBaseObject)
        if index == -1
            return -1
        else
            return index + 128
        endif
    else
        return index
    endif
endFunction

int function BigArrayFindInt_Do(Int aiValue, Int[] array1, Int[] array2)
    int index = array1.Find(aiValue)
    if index == -1
        index = array2.Find(aiValue)
        if index == -1
            return -1
        else
            return index + 128
        endif
    else
        return index
    endif
endFunction

int function BigArrayFindRef_Do(ObjectReference akReference, ObjectReference[] array1, ObjectReference[] array2)
    int index = array1.Find(akReference)
    if index == -1
        index = array2.Find(akReference)
        if index == -1
            return -1
        else
            return index + 128
        endif
    else
        return index
    endif
endFunction

int function BigArrayFindNextRef_Do(ObjectReference akReference, ObjectReference[] array1, ObjectReference[] array2, int starting_index)
    int index
    if starting_index < 128
        index = array1.Find(akReference, starting_index)
        if index == -1
            index = array2.Find(akReference, starting_index)
            if index == -1
                return -1
            else
                return index + 128
            endif
        else
            return index
        endif
    else
        index = array2.Find(akReference, starting_index - 128)
        if index == -1
            return -1
        else
            return index + 128
        endif
    endif
endFunction

Form function BigArrayGetFormAtIndex_Do(int index, Form[] array1, Form[] array2)
    if index > 127
        index -= 128
        return array2[index]
    else
        return array1[index]
    endif
endFunction

Int function BigArrayGetIntAtIndex_Do(int index, Int[] array1, Int[] array2)
    if index > 127
        index -= 128
        return array2[index]
    else
        return array1[index]
    endif
endFunction

ObjectReference function BigArrayGetRefAtIndex_Do(int index, ObjectReference[] array1, ObjectReference[] array2)
    if index > 127
        index -= 128
        return array2[index]
    else
        return array1[index]
    endif
endFunction

function BigArrayAddForm_Do(int index, Form akBaseObject, Form[] array1, Form[] array2)
    if index > 254
        ;@TODO: Log error
        return
    endif
    if index > 127
        array2[(128 - index)] = akBaseObject
    else
        array1[index] = akBaseObject
    endif
endFunction

function BigArrayAddInt_Do(int index, Int aiValue, Int[] array1, Int[] array2)
    if index > 254
        ;@TODO: Log error
        return
    endif
    if index > 127
        array2[(128 - index)] = aiValue
    else
        array1[index] = aiValue
    endif
endFunction

function BigArrayAddRef_Do(int index, ObjectReference akReference, ObjectReference[] array1, ObjectReference[] array2)
    if index > 254
        ;@TODO: Log error
        return
    endif
    if index > 127
        array2[(128 - index)] = akReference
    else
        array1[index] = akReference
    endif
endFunction

function BigArrayClearForm_Do(int index, Form[] array1, Form[] array2)
    if index > 254
        ;@TODO: Log error
        return
    endif
    if index > 127
        array2[(128 - index)] = None
    else
        array1[index] = None
    endif
endFunction

function BigArrayClearInt_Do(int index, Int[] array1, Int[] array2)
    if index > 254
        ;@TODO: Log error
        return
    endif
    if index > 127
        array2[(128 - index)] = 0
    else
        array1[index] = 0
    endif
endFunction

function BigArrayClearRef_Do(int index, ObjectReference[] array1, ObjectReference[] array2)
    if index > 254
        ;@TODO: Log error
        return
    endif
    if index > 127
        array2[(128 - index)] = None
    else
        array1[index] = None
    endif
endFunction

function ArrayAddInt(Int[] myArray, Int aiValue)
    int index = myArray.Find(0)
    if index >= 0
        myArray[index] = aiValue
    endif
endFunction