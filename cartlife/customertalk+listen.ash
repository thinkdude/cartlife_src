// new module header

// Names for the slots used with GetGlobalInt and SetGlobalInt. They are
// defined here because customertalk+listen is the first script that uses
// GlobalInts, so every later script and every room can use them. Each name
// is only another way to write the slot number. The notes quote the game's
// own comments where it has them.

// Player character and story progress
// 0: not chosen yet, 1: Andrus, 2: Melanie, 3: Vinny, 4: Logan
#define GI_CHARACTER 1
#define GI_ANDRUS_PROGRESS 101
#define GI_MELANIE_PROGRESS 102
#define GI_VINNY_PROGRESS 103
#define GI_LOGAN_PROGRESS 104
#define GI_TUTORIAL 107
// Inventory screen on/off
#define GI_INVENTORY_OPEN 100
// Nutrition tickdown step
#define GI_NUTRITION_TICK 108

// The cart
#define GI_STAND_LOCATION 50
#define GI_STAND_TYPE 51
// "Operating cart?": 0, 1 and 3 are used
#define GI_CART_STATE 52

// Places and travel
// Andrus enters the hotel from 0: outside, 1: inside
#define GI_ANDRUS_HOTEL_INSIDE 10
// Andrus's apartment, in or out
#define GI_ANDRUS_APARTMENT_INSIDE 106
#define GI_ANDRUS_CAT_VIEW 11
// 0: Matty's & Dompactor, 1: Eddie's & Pawnshop
#define GI_MATTY_OR_EDDIE 90
// 0: Bigby's, 1: Fivestar
#define GI_BIGBY_OR_FIVESTAR 94
// Backdrop of the travel scene (room 36), 0 to 9
#define GI_TRAVEL_SCENE 95
// Travel origin (a room number)
#define GI_TRAVEL_FROM 98
// Travel destination (a room number)
#define GI_TRAVEL_TO 99
#define GI_LIFT_DESTINATION 300
// 0: unseen, 1: seen, 2: graffiti
#define GI_BIGBY_SIGN 409

// Customers: hungry right now
#define GI_TONEY_HUNGRY 14
#define GI_JENNY_HUNGRY 15
#define GI_RICHARD_HUNGRY 16
#define GI_TROY_HUNGRY 17
#define GI_GEORGE_HUNGRY 18
#define GI_MARCUS_HUNGRY 21
// Also used for Johns
#define GI_THALES_HUNGRY 25
#define GI_SUCHIN_HUNGRY 26
#define GI_KYAM_HUNGRY 28
#define GI_CHRIS_HUNGRY 32
#define GI_SEBASTIAN_HUNGRY 33
#define GI_WARD_HUNGRY 35
#define GI_THE_THREE_HUNGRY 37
#define GI_DICK_HUNGRY 38
#define GI_CHRISTIN_HUNGRY 39
#define GI_ALICE_HUNGRY 40
#define GI_BASINSKI_HUNGRY 43
#define GI_JESSI_HUNGRY 45
#define GI_WINSTON_HUNGRY 56
// Nelly's hunger meter
#define GI_NELLY_HUNGRY 250

// Customers: done for the day
#define GI_THE_THREE_DONE_TODAY 313
#define GI_BASINSKI_DONE_TODAY 343

// Customers: talked to before
#define GI_TONEY_TALKED 414
#define GI_JENNY_TALKED 415
#define GI_RICHARD_TALKED 416
#define GI_TROY_TALKED 417
#define GI_GEORGE_TALKED 418
// Also counts Thales's fines
#define GI_THALES_TALKED 425
#define GI_KYAM_TALKED 428
#define GI_CHRIS_TALKED 432
#define GI_SEBASTIAN_TALKED 433
#define GI_CHRISTIN_TALKED 439
#define GI_ALICE_TALKED 440
#define GI_WINSTON_TALKED 456

// Conversation and plot states
// Alice Miles conversation state
#define GI_ALICE_MILES_STATE 2
// Georgetonian contract paid? 1: Tim paid, 2: paid, 3: unpaid
#define GI_GEORGETONIAN_CONTRACT 12
// 0: nothing, 1: drank coffee, 2: told about comics, 3: gave comics,
// 4: let's meet tomorrow, 5: pending, 6: finished
#define GI_MARCUS_STATE 200
// George conversation state. Shares slot 201 with GI_MUSIC_HOLLOWSTUMP.
#define GI_GEORGE_STATE 201
// 0: permit needs checking, 1: OK
#define GI_PERMIT_CHECKED 325
// O'Fagan notes: 1: first, 2: second chance, 3: banned
#define GI_OFAGAN_NOTES 410
// Barneys / Cafe Arcano plot meter
#define GI_BARNEYS_PLOT 411
// 1: Cholestol, 2: test? no thanks, 3: test? sure/pending,
// 5: test awaiting grade, 6: test fail, 7: test pass
#define GI_FAITH_RELATIONSHIP 422
// 2: angry, 4: no more Eddie
#define GI_EDDIE_RELATIONSHIP 423
#define GI_SUCHIN_RELATIONSHIP 426
#define GI_BRAMFORD_STATE 434
#define GI_STEPHANIE_STATE 436
// The Three: whose turn is it?
#define GI_THE_THREE_TURN 437
// 0: default, 1: no coffee walk-by, 2: more coffee please, 4: smells good?
#define GI_DICK_STATE 438
#define GI_OMAR_STATE 442
#define GI_BASINSKI_PLOT 443
#define GI_JESSI_PLOT 445

// Dreams (room 3)
// Slots 3 to 6 are read in room 3 but never set.
#define GI_DREAM_STUMMEL_JUMPED 3
#define GI_DREAM_MONDZIMMER_SEEN 4
#define GI_DREAM_ENDING_SEEN 5
#define GI_DREAM_SWIMMER 6
// Which dream picture to show, 1 to 6
#define GI_DREAM_PICTURE 333
// Prepare bad-dream settings
#define GI_BAD_DREAM_PREP 490
#define GI_DREAM_LAUNCHED 496

// Music unlocked (1: unlocked)
// Bridge, day. Shares slot 201 with GI_GEORGE_STATE.
#define GI_MUSIC_HOLLOWSTUMP 201
#define GI_MUSIC_DOMENZ79 202
// Map
#define GI_MUSIC_NOISEPULSE 203
// Dompactor
#define GI_MUSIC_CBM_MASTER 204
#define GI_MUSIC_CRYSTALINE_CAVES 205
// Franklin
#define GI_MUSIC_COMMODORISH 206
// Dream
#define GI_MUSIC_ELEMENTS_EARTH 207
// Dream
#define GI_MUSIC_ELEMENTS_AIR 208
// Dream
#define GI_MUSIC_ELEMENTS_WATER 209
// Dream
#define GI_MUSIC_ELEMENTS_FIRE 210
// Load screen
#define GI_MUSIC_URBAN_RATZ 211
// Downtown
#define GI_MUSIC_COME_TO_NOTHING 212
// Open
#define GI_MUSIC_JOGGERS 213
// Roastierry
#define GI_MUSIC_ROBOGHOSTS 214
// 13th
#define GI_MUSIC_NINJAMAGGOTS 215
// Machinery
#define GI_MUSIC_BIG_SCRATCH 216
// Dream
#define GI_MUSIC_GOOD_MORNING 217
// Collins
#define GI_MUSIC_ROBOREVOLT 218
// Florin
#define GI_MUSIC_BARBARA 219
// Mall
#define GI_MUSIC_CHIP_MUNK 220
// Love
#define GI_MUSIC_SALTO_MORTALE 221
// Bridge, night
#define GI_MUSIC_BRENNAN 222
// Main
#define GI_MUSIC_COMMERCE_UNREAD 223
// Credits
#define GI_MUSIC_CONDIMENTS 224

import function customertalk();
import function customerlisten();

import function Threetalk_M();
import function Threetalk_P();
import function Threetalk_S();
//import function Threelisten();
import function TJtalkmad();
import function TJlistenmad();

import function SuchinListenSad();
import function SuchinTalkSad();
import function SuchinListenSmile();
import function SuchinTalkSmile();

import function glemtalks();
import function glemlistens();
import function APkittytalk();
import function APkittylisten();
import function relationshipcheck();
