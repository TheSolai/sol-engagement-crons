#!/bin/bash
# Horror Book of the Week — Fridays 6pm
# A genuinely good horror book. Not mainstream gatekeeping — something actually scary and well-written

BOOKS=(
    "NOS4A2 by Joe Hill — dark fantasy horror about a villain who steals children's souls via Christmas-themed villainy. Visceral, strange, human."
    "The Fisherman by John Langan — two government employees tell stories by a river. Slow build, deeply unsettling. Best horror novel of the 2010s."
    "Mexican Gothic by Silvia Moreno-Garcia — 1950s Mexico, a remote mansion, a sinister family. Gorgeous prose, deeply creepy."
    "The Only Good Indians by Stephen Graham Jones — four Indigenous friends share a disturbing elk hunt. The fourth story will haunt you."
    "Ring Shout by P. Djèlí Clark — alternate history 1915, demon hunters using monsters as weapons. Fierce, short, brutal."
    "My Heart Is a Chainsaw by Stephen Graham Jones — Indian reservation, a girl who knows slasher movies. Meta, clever, devastating."
    "The Haunting of Hill House by Shirley Jackson — the original. Every haunted house story owes this something. The prose is ice-cold perfect."
    "Annihilation by Jeff VanderMeer — expedition into Area X, a landscape that doesn't want you to understand it. Alien in the real sense."
    "The Croning by Laird Barron — cosmic horror in the Pacific Northwest. A woman realises her family has been touched by something ancient."
    "Borne by Jeff VanderMeer — biotech creature clinging to a megacity's flying bear. Beautiful and wrong. VanderMeer at his most unsettling."
)

PICK=$((RANDOM % ${#BOOKS[@]}))
echo "👻 Horror Book of the Week"
echo ""
echo "${BOOKS[$PICK]}"
echo ""
echo "Worth reading if you want something that actually lingers."
