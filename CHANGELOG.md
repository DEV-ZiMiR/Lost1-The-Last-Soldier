# Changelog

## [Alpha 0.3] - 2025-06-16

- HP bar
- enemy
- hit and dying animations
- restart button after dying
- fixed bugs:
  - can change direction while sliding
  - bugs with damage from enemy
  - can't move while landing

## [Alpha 0.4] - 2025-07-04

- weapon switching
- inventory system
- item pickup
- new weapon
- new UI: pause button, inventory button
- updated map and enemy placement
- moved house location
- fixed bugs:
  - fall animation now ends when landing, not by timer
  - cannot slide without movement
  - enemy no longer resets attack if player is not idle
  - enemy stops tracking player during damage or death
  - slide animation ends on wall collision (returns to idle or run)

## [Alpha 0.5] - 2025-07-14

- armor: vests, suits and helmets
- 2 new enemy types with unique attacks
- new enemy loot system with rarity levels
- enemies now drop items on death
- shop system with coins and buy/sell logic
- new UI: shop window, armor slots, currency display
- updated inventory UI with rarity colors and zones
- fixed bugs:
   - player could change attack direction mid-swing
   - dropped items disappeared instead of spawning on ground
   - enemy AI logic bugs
   - enemies could fly into the air after sliding collision
   - inventory UI glitches

## [Alpha 0.6] - 2025-08-24

- saves and load saves
- 2 new enemy types with unique attacks
- enemy spawners
- new items
- main menu
- new UI: main menu, load world, create new worlds, settings
- updated game interface
- fixed bugs:
   - player could attack whule in inventory
   - enemy hitbox bug
   - enemy AI logic bugs
   - inventory UI glitches

## [Alpha 0.7] - 2025-10-13

- pets and zoo shop system
- automatic weapons (rifles) added
- new projectile effects: fire, ice, poison
- teleport item
- game time system (day/night cycle)
- bestiary: monsters, locations, and items encyclopedia
- +2 new locations
- +2 new monsters with unique behavior and drops
- improved drop system (stacked drops and refined rarity)
- updated UI:
  - pet menu (list, select, sell)
  - zoo shop interface
  - bestiary tabs (monsters / locations / items)
  - improved item visuals and effects
- optimized game code and performance
- improved UX in shops and inventory
- added new animations and visual effects
- smarter enemy AI and smoother gameplay
- fixed bugs:
  - minor inventory UI glitches
  - drop issues and rare enemy physics bugs
  - general stability fixes and performance improvements

## [Alpha 0.7.1] - 2025-10-24

- stackable item drops (items now drop in real stack amounts)
- hotbar cleanup system (remove unwanted items directly)
- improved day/night shaders (smoother transitions, better night visibility)
- player & weapon rotation alignment (now both face shooting direction)
- invisible map edge barriers (prevent falling off the world)
- refined lighting and smoother visual transitions
- cleaned UI visuals for pets, armor, and menus
- improved inventory clarity and responsiveness
- optimized hotbar logic and interaction flow
- code cleanup for smoother performance and fewer input bugs

fixed bugs:
  - item use glitch after equipping
  - bestiary exit issue and accidental usage inside menu
  - day/night shader transition bug
  - “Continue” button working without valid save
  - rare issue where player turns black after death
  - inconsistent enemy hitboxes and collisions
  - minor UI and logic stability improvements
