# ChessGolf: Concept Overview

ChessGolf is a turn-based puzzle game that combines chess movement mechanics with golf course navigation. Players must reach the hole in as few moves as possible while adapting to changing movement capabilities determined by the terrain.

## Core Mechanics

- **Grid-Based Movement**: Players navigate a square grid representing a golf course
- **Terrain-Based Pieces**: Each type of terrain transforms the player into a different chess piece for their next move
- **Obstacle Navigation**: Some terrain features act as obstacles that require specific pieces to overcome
- **Move Optimization**: The goal is to complete each level in the minimum number of moves
- **Movement Constraints**: Players can only move within terrain boundaries - when crossing from one terrain type to another, movement ends at the new terrain and the player adopts that piece's movement pattern for their next turn

## Terrain-Piece Associations

```
Terrain Type → Chess Piece
---------------------
Fairway → Queen (moves any number of squares in any direction)
Green → Rook (moves any number of squares horizontally or vertically)
Rough → Bishop (moves any number of squares diagonally)
Hill → Knight (L-shaped movement, can jump over obstacles)
Sand → Pawn (moves one square forward)

Trees → Cannot land here (but Knights can jump over)
Water → Cannot land here
Hole → Victory condition
```

## Game Modes

### Solo
Pure puzzle-solving where the player must find the optimal path to the hole through a challenging course. This tests the player's ability to plan ahead and understand how terrain changes will affect their movement options.

### Speed Race
The player races against an AI opponent that follows the same movement rules. Both start from different positions and aim to reach the hole first. The AI follows predictable patterns, maintaining the puzzle-solving nature of the game.

### Fight
Multiple AI opponents exist on the course and can capture the player according to chess rules. Since only one piece moves per turn, this becomes a strategic puzzle of avoiding or capturing enemy pieces while navigating toward the hole.

## Additional Features

- **Procedural Level Generation**: Endless unique challenges
- **Difficulty Progression**: Gradually increasing complexity as players master the mechanics
- **Visual Feedback**: Clear indication of available moves based on current piece type
- **Move Counter**: Track performance against par for each hole

ChessGolf offers a fresh twist on puzzle games by combining the strategic depth of chess with the goal-oriented nature of golf, creating a unique gaming experience that's easy to understand but challenging to master.
