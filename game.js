// Game configuration
const terrainMapping = {
    'f': { name: 'fairway', piece: 'Q', obstacle: false },
    'g': { name: 'green', piece: 'R', obstacle: false },
    'r': { name: 'rough', piece: 'B', obstacle: false },
    'h': { name: 'hill', piece: 'N', obstacle: false },
    's': { name: 'sand', piece: 'P', obstacle: false },
    't': { name: 'tree', piece: null, obstacle: true },
    'w': { name: 'water', piece: null, obstacle: true },
    'H': { name: 'hole', piece: null, obstacle: false, goal: true }
};

// Game state
let playerPosition = { row: 20, col: 3 }; // Starting position
let currentPiece = 'Q'; // Start with Queen (fairway)
let moveCount = 0;
let validMoves = [];

// Define the game field
let field = [
    "rrrrrrrrrrrrrrrr",
    "rrgggggrrrrrrrrr",
    "rrgggggrrrrrrrrr",
    "rrggHggrrrrrrrrr",
    "rrgggggrhhhhrrrr",
    "rrggggghttthhrrr",
    "rrttthttthttthrr",
    "rrthttthttththhr",
    "rrttthttthttthrr",
    "rrrsttwwtttthhhr",
    "ssssswwwwhhhhhrr",
    "ssssswwwwhhhhhhr",
    "ssssssssshhhhhrr",
    "ssssssssrrhhhhhr",
    "sssssssrrtthhhrr",
    "ssssffrrttttttrr",
    "sssffffttttttrrr",
    "rrfffffffffffrrr",
    "rrfffffffffffrrr",
    "rrfffffffffffrrr",
    "rrfffffffffffrrr",
    "rrfffffffffffrrr",
];

// DOM elements
const gameBoard = document.getElementById('game-board');
const moveCountElement = document.getElementById('move-count');
const startScreen = document.getElementById('start-screen');
const endScreen = document.getElementById('end-screen');
const startButton = document.getElementById('start-button');
const playAgainButton = document.getElementById('play-again-button');
const restartButton = document.getElementById('in-game-restart');
const finalMovesElement = document.getElementById('final-moves');

// Initialize the game
function initGame() {
    playerPosition = { row: 20, col: 3 }; // Starting position
    currentPiece = terrainMapping[field[playerPosition.row][playerPosition.col]].piece;

    // Set the grid columns based on field width
    gameBoard.style.gridTemplateColumns = `repeat(${field[0].length}, var(--cell-size))`;
    
    // Clear the board
    gameBoard.innerHTML = '';

    // Create the cells
    for (let row = 0; row < field.length; row++) {
        for (let col = 0; col < field[row].length; col++) {
            const cell = document.createElement('div');
            cell.className = 'cell';
            
            const terrainType = field[row][col];
            const terrain = terrainMapping[terrainType];
            
            cell.style.backgroundImage = `url('assets/${terrain.name}.png')`;
            cell.dataset.row = row;
            cell.dataset.col = col;
            cell.dataset.terrain = terrainType;
            
            cell.addEventListener('click', () => handleCellClick(row, col));
            
            gameBoard.appendChild(cell);
        }
    }

    // Place the player
    updatePlayerPosition();
    
    // Calculate valid moves based on starting position
    updateValidMoves();
    
    // Reset move count
    moveCount = 0;
    moveCountElement.textContent = moveCount;
}

// Update player position on the board
function updatePlayerPosition() {
    // Remove previous player element
    const prevPlayer = document.querySelector('.player');
    if (prevPlayer) {
        prevPlayer.remove();
    }
    
    // Get the cell at player position
    const cell = getCellAt(playerPosition.row, playerPosition.col);
    if (!cell) return;
    
    // Create and add player element
    const playerElement = document.createElement('div');
    playerElement.className = 'player';
    playerElement.style.backgroundImage = `url('assets/w${currentPiece}.png')`;
    cell.appendChild(playerElement);
    
    // Scroll to player if needed
    cell.scrollIntoView({ behavior: 'smooth', block: 'center', inline: 'center' });
}

// Calculate valid moves based on current position and piece
function updateValidMoves() {
    // Clear previous valid moves
    clearValidMoves();
    
    validMoves = [];
    
    // Calculate moves based on current piece
    switch (currentPiece) {
        case 'Q': // Queen (fairway)
            addStraightMoves(true, true); // Both straight and diagonal
            break;
        case 'R': // Rook (green)
            addStraightMoves(true, false); // Only straight
            break;
        case 'B': // Bishop (rough)
            addStraightMoves(false, true); // Only diagonal
            break;
        case 'N': // Knight (hill)
            addKnightMoves();
            break;
        case 'P': // Pawn (sand)
            addPawnMoves();
            break;
    }
    
    // Show valid moves
    showValidMoves();
}

// Add straight and/or diagonal moves
function addStraightMoves(straight, diagonal) {
    const directions = [];
    if (straight) {
        directions.push({ row: 0, col: 1 });  // Right
        directions.push({ row: 1, col: 0 });  // Down
        directions.push({ row: 0, col: -1 }); // Left
        directions.push({ row: -1, col: 0 }); // Up
    }
    if (diagonal) {
        directions.push({ row: 1, col: 1 });   // Down-Right
        directions.push({ row: 1, col: -1 });  // Down-Left
        directions.push({ row: -1, col: 1 });  // Up-Right
        directions.push({ row: -1, col: -1 }); // Up-Left
    }
    
    // Get the current terrain type
    const currentTerrainType = field[playerPosition.row][playerPosition.col];
    
    // For each direction, add moves until hitting an obstacle, edge, or different terrain+1
    directions.forEach(dir => {
        let r = playerPosition.row + dir.row;
        let c = playerPosition.col + dir.col;
        
        let encounteredDifferentTerrain = false;
        
        while (isValidCell(r, c)) {
            const terrainType = field[r][c];
            const terrain = terrainMapping[terrainType];
            
            // Check if we're entering a different terrain
            if (terrainType !== currentTerrainType) {
                // If we've already encountered a different terrain, don't add this move
                if (encounteredDifferentTerrain) {
                    break;
                }
                encounteredDifferentTerrain = true;
            }
            
            validMoves.push({ row: r, col: c });
            
            // Stop if this is an obstacle or goal
            if (terrain.obstacle || terrain.goal) break;
            
            r += dir.row;
            c += dir.col;
        }
    });
}

// Add knight moves (L-shaped)
function addKnightMoves() {
    const knightMoves = [
        { row: -2, col: -1 }, { row: -2, col: 1 },
        { row: -1, col: -2 }, { row: -1, col: 2 },
        { row: 1, col: -2 }, { row: 1, col: 2 },
        { row: 2, col: -1 }, { row: 2, col: 1 }
    ];
    
    knightMoves.forEach(move => {
        const r = playerPosition.row + move.row;
        const c = playerPosition.col + move.col;
        
        if (isValidCell(r, c)) {
            const terrain = terrainMapping[field[r][c]];
            if (!terrain.obstacle || terrain.goal) {
                validMoves.push({ row: r, col: c });
            }
        }
    });
}

// Add pawn moves (one square forward)
function addPawnMoves() {
    // Assuming "forward" is upward (decreasing row)
    const r = playerPosition.row - 1;
    const c = playerPosition.col;
    
    if (isValidCell(r, c)) {
        const terrain = terrainMapping[field[r][c]];
        if (!terrain.obstacle || terrain.goal) {
            validMoves.push({ row: r, col: c });
        }
    }
    
    // For pawns, since they only move one square, the terrain restriction 
    // doesn't affect their movement as they're already limited to one square
}

// Check if a cell is within the board and can be moved to
function isValidCell(row, col) {
    // Check if within bounds
    if (row < 0 || row >= field.length || col < 0 || col >= field[0].length) {
        return false;
    }
    
    const terrain = terrainMapping[field[row][col]];
    
    // Check if it's an obstacle (except for goal)
    if (terrain.obstacle && !terrain.goal) {
        return false;
    }
    
    return true;
}

// Show valid moves on the board
function showValidMoves() {
    validMoves.forEach(move => {
        const cell = getCellAt(move.row, move.col);
        if (cell) {
            const moveIndicator = document.createElement('div');
            moveIndicator.className = 'valid-move';
            cell.appendChild(moveIndicator);
        }
    });
}

// Clear valid move indicators
function clearValidMoves() {
    const indicators = document.querySelectorAll('.valid-move');
    indicators.forEach(indicator => indicator.remove());
}

// Handle cell click
function handleCellClick(row, col) {
    // Check if this is a valid move
    const moveIndex = validMoves.findIndex(move => move.row === row && move.col === col);
    
    if (moveIndex === -1) return; // Not a valid move
    
    // Move the player
    playerPosition.row = row;
    playerPosition.col = col;
    moveCount++;
    moveCountElement.textContent = moveCount;
    
    // Update piece based on new terrain
    const newTerrain = terrainMapping[field[row][col]];
    
    // Check if reached the goal
    if (newTerrain.goal) {
        endGame();
        return;
    }
    
    // Update current piece based on terrain
    if (newTerrain.piece) {
        currentPiece = newTerrain.piece;
    }
    
    // Update player position and valid moves
    updatePlayerPosition();
    updateValidMoves();
}

// Get cell element at specific coordinates
function getCellAt(row, col) {
    return document.querySelector(`.cell[data-row="${row}"][data-col="${col}"]`);
}

// End the game
function endGame() {
    finalMovesElement.textContent = moveCount;
    endScreen.style.display = 'flex';
}

// Event listeners
startButton.addEventListener('click', () => {
    startScreen.style.display = 'none';
    initGame();
});

playAgainButton.addEventListener('click', () => {
    endScreen.style.display = 'none';
    initGame();
});

restartButton.addEventListener('click', () => {
    initGame();
    updatePlayerPosition();
});

document.getElementById('in-game-restart').addEventListener('click', () => {
    initGame();
});

// Prevent zooming on double tap on mobile
document.addEventListener('touchstart', function(event) {
    if (event.touches.length > 1) {
        event.preventDefault();
    }
}, { passive: false });

// Prevent zooming on double tap
let lastTouchEnd = 0;
document.addEventListener('touchend', function(event) {
    const now = Date.now();
    if (now - lastTouchEnd <= 300) {
        event.preventDefault();
    }
    lastTouchEnd = now;
}, { passive: false });
