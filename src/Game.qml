import QtQuick 2.9
import Nemo.Configuration 1.0
import org.nemomobile.lipstick 0.1
import org.asteroid.utils 1.0
import org.asteroid.controls 1.0

Item {
    id: main
    anchors.fill: parent

    Item {
        id: logic

        property var score: 0
        property alias bestScore: bestScoreConf.value

        property var rows: 4
        property var cols: 4

        // The game field.
        property var cells: []

        // UI
        // Contains the empty grid cells
        // This is an array of indices.
        property var emptyGridCells: []

        ConfigurationValue {
            id: gridCells
            key: "/2048/grid"
            defaultValue: ""
        }

        ConfigurationValue {
            id: gridScore
            key: "/2048/score"
            defaultValue: ""
        }

        ConfigurationValue {
            id: bestScoreConf
            key: "/2048/bestScore"
            defaultValue: 0
        }

        function movePossible() {
            for (var x=0; x<rows; x++) {
                for (var y=0; y<cols-1; y++) {
                    if (cells[x][y] == cells[x][y+1])
                        return true
                }
            }

            for (var x=0; x<rows-1; x++) {
                for (var y=0; y<cols; y++) {
                    if (cells[x][y] == cells[x+1][y])
                        return true
                }
            }
            return false
        }

        function moveCell(x1, y1, x2, y2) {
            var cell1 = cells[x1][y1];
            var cell2 = cells[x2][y2];

            // A cell cannot move over an existing cell with a different value.
            if ((cell1 !== 0 && cell2 !== 0) && cell1 !== cell2)
                return false

            // If can move to empty spot or spot with same value.
            if ((cell1 !== 0 && cell1 === cell2) || (cell1 !== 0 && cell2 === 0)) {
                cells[x1][y1] = 0;

                for (var i=0;i<logic.rows*logic.cols;i++) {
                    if ((cellsGrid.itemAt(i).x1 == -1) || (cellsGrid.itemAt(i).y1 == -1)) continue
                    if ((cellsGrid.itemAt(i).x1 == x1) && (cellsGrid.itemAt(i).y1 == y1)) {
                        cellsGrid.itemAt(i).animateMove = true
                        cellsGrid.itemAt(i).x1 = x2
                        cellsGrid.itemAt(i).y1 = y2
                        animationTimer.start()
                        break
                    }
                }
            }

            // Cell moves to position where same valued cell exists.
            if (cell1 !== 0 && cell1 === cell2) {
                cells[x2][y2] *= 2;
                score += cells[x2][y2]

                for (var i=0;i<logic.rows*logic.cols;i++) {
                    if ((cellsGrid.itemAt(i).x1 == -1) || (cellsGrid.itemAt(i).y1 == -1)) continue
                    if ((cellsGrid.itemAt(i).x1 == x2) && (cellsGrid.itemAt(i).y1 == y2)) {
                        cellsGrid.itemAt(i).val = cells[x2][y2]
                        cellsGrid.itemAt(i).pop = true
                    }
                }
                return false;
            }

            // Cell moves to empty position.
            if (cell1 !== 0 && cell2 === 0) {
                cells[x2][y2] = cell1;
                return true;
            }
            return true
        }

        function move(gesture) {
            if (animationTimer.running) return

            if (gesture == "left" || gesture == "up") {
                for (var x=0; x<rows; x++) {
                    for (var y=0; y<cols; y++) {
                        for (var j= y+1; j<rows; j++) {
                            if (gesture == "left") {
                                if (!moveCell(j, x, y, x))
                                    break;
                            } else {
                                if (!moveCell(x, j, x, y))
                                    break;
                            }
                        }
                    }
                }
            }

            if (gesture == "right" || gesture == "down") {
                for (var x=0; x<rows; x++) {
                    for (var y=cols-1; y>=0; y--) {
                        for (var j= y-1; j>=0; j--) {
                            if (gesture == "right") {
                                if (!moveCell(j, x, y, x))
                                    break;
                            } else {
                                if (!moveCell(x, j, x, y))
                                    break;
                            }
                        }
                    }
                }
            }
        }

        function synchronize() {
            gridScore.value = score
            var cellString = ""
            for (var x=0;x<rows;x++) {
                for (var y=0; y<cols; y++) {
                    cellString = cellString + cells[x][y] + ","
                }
                cellString = cellString + ";"
            }
            gridCells.value = cellString
        }

        function restore() {
            if (gridCells.value.length == 0) return false

            score = gridScore.value
            for (var i=0; i<rows*cols;i++) {
                emptyGridCells[i] = i
                cellsGrid.itemAt(i).x1 = -1
                cellsGrid.itemAt(i).y1 = -1
                cellsGrid.itemAt(i).val = 0
            }

            var emptyCells = 0
            cells = gridCells.value.split(";")
            for (var x=0;x<rows;x++) {
                cells[x] = cells[x].split(",")
                for (var y=0;y<cols;y++) {
                    cells[x][y] = parseInt(cells[x][y])

                    // UI
                    if (cells[x][y] != 0) {
                        var emptyGrid = emptyGridCells[0]
                        emptyGridCells.shift()

                        cellsGrid.itemAt(emptyGrid).val = cells[x][y]
                        cellsGrid.itemAt(emptyGrid).x1 = x
                        cellsGrid.itemAt(emptyGrid).y1 = y
                    } else {
                        emptyCells ++
                    }
                }
            }

            if ((emptyCells === 0) && !movePossible()) {
                console.log("restore::Moving is no longer possbile! GAME OVER!!")
                bestScore = Math.max(bestScore, score)
                gameOver.visible = true
            }
            return true
        }

        /**
            Attempt to place a tile of a random value on a random free spot on the grid.
            If there is no free spot or no move possible after placing the tile, the game will transition to a game over state.
         */
        function randCell() {
            var emptyCells = []
            for (var x=0; x<rows; x++) {
                for (var y=0; y<cols; y++) {
                    if (cells[x][y] == 0) {
                        emptyCells.push([x,y])
                    }
                }
            }
            if (!emptyCells.length) return

            var emptyCell = emptyCells[Math.floor(Math.random()*emptyCells.length)]
            var x = emptyCell[0]
            var y = emptyCell[1]
            cells[x][y] = (Math.random() < 0.9) ? 2 : 4

            // UI
            var emptyGrid = emptyGridCells[0]
            emptyGridCells.shift()

            cellsGrid.itemAt(emptyGrid).animateMove = false
            cellsGrid.itemAt(emptyGrid).val = cells[x][y]
            cellsGrid.itemAt(emptyGrid).x1 = x
            cellsGrid.itemAt(emptyGrid).y1 = y

            if ((emptyCells.length<=1) && !movePossible()) {
                console.log("randCell::Moving is no longer possbile! GAME OVER!!")
                bestScore = Math.max(bestScore, score)
                gameOver.visible = true
            }
        }

        /**
            After the grid has moved it will be possible that some tiles are combined (2 and 2 will merge into 4).
            This results in multiple tiles at the same location. The duplicates can be removed from the grid.
         */
        function removeDuplicateGridCells() {
            for (var i=0;i<rows*cols;i++) {
                if ((cellsGrid.itemAt(i).x1 == -1) || (cellsGrid.itemAt(i).y1 == -1)) continue

                for (var j=i+1;j<rows*cols;j++) {
                    if ((cellsGrid.itemAt(i).x1 == -1) || (cellsGrid.itemAt(i).y1 == -1)) continue
                    if ((cellsGrid.itemAt(i).x1 === cellsGrid.itemAt(j).x1) && (cellsGrid.itemAt(i).y1 === cellsGrid.itemAt(j).y1)) {
                        cellsGrid.itemAt(j).animateMove = false
                        cellsGrid.itemAt(j).val = 0
                        cellsGrid.itemAt(j).x1 = -1
                        cellsGrid.itemAt(j).y1 = -1
                        emptyGridCells[emptyGridCells.length] = j
                    }
                }
            }
        }

        function reset() {
            if (gameOver.visible == false) {
                if (restore()) {
                    return
                }
            }

            gameOver.visible = false
            for (var x=0; x<rows; x++) {
                cells[x] = []
                for (var y=0; y<cols; y++) {
                    cells[x][y] = 0
                }
            }
            score = 0
            for (var i=0;i<rows*cols;i++) {
                emptyGridCells[i] = i
                cellsGrid.itemAt(i).x1 = -1
                cellsGrid.itemAt(i).y1 = -1
                cellsGrid.itemAt(i).val = 0
            }
            randCell()
            randCell()
            synchronize()
        }

        Timer {
            id: animationTimer
            interval: 200
            repeat: false
            onTriggered: {
                logic.removeDuplicateGridCells()
                logic.randCell()
                logic.synchronize()
            }
        }

        Component.onCompleted: {
            logic.reset()
        }
    }

    Item {
        id: gameView
        anchors.fill: parent
        transform: Rotation { origin.x: width/2; origin.y: height/2; angle: 45}
        opacity: gameOver.visible ? 0.8 : 1
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InCurve } }

        Item {
            id: scoreBoard
            width: Dims.l(100)
            height: Dims.l(100)
            anchors.centerIn: parent

            opacity: 0.7

            Behavior on opacity { NumberAnimation { duration: 200 } }
            Rectangle {
                transform: Rotation {origin.x: 0; origin.y: 0; angle: -90}
                x: parent.width - height
                y: parent.height*0.5 + width/2
                width: parent.width*0.3
                height: parent.height*0.12
                radius: 3
                color: "#af590b"

                Text {
                    anchors.top: parent.top
                    anchors.topMargin: parent.height*0.1
                    width: parent.width
                    color: "#fff"
                    text: logic.score
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 20
                }
                Text {
                    anchors.top: parent.top
                    anchors.topMargin: parent.height*0.6
                    width: parent.width
                    color: "#eee4da"
                    //% "SCORE"
                    text: qsTrId("id-score")
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 12
                }
            }

            Rectangle {
                x: parent.width*0.35
                y: parent.height*0.88
                width: parent.width*0.3
                height: parent.height*0.12
                radius: 3
                color: "#af590b"

                Text {
                    anchors.top: parent.top
                    anchors.topMargin: parent.height*0.1
                    width: parent.width
                    color: "#fff"
                    text: logic.bestScore
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 20
                }
                Text {
                    anchors.top: parent.top
                    anchors.topMargin: parent.height*0.6
                    width: parent.width
                    color: "#eee4da"
                    //% "BEST"
                    text: qsTrId("id-best")
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 12
                }
            }
        }

        Item {
            id: board
            // As the field is rotated by 45°, make sure that the diagonal of the field matches the minimum length.
            property int fieldSize: Math.floor(Math.sqrt(Math.pow(Dims.l(100), 2)/2))

            width: fieldSize
            height: fieldSize
            anchors.centerIn: parent

            Grid {
                id: grid
                anchors.fill: parent
                columns: 4
                rows: 4
                opacity: 0.3

                Repeater {
                    model: grid.columns * grid.rows

                    Item {
                        width: grid.width/grid.columns
                        height: grid.height/grid.rows

                        Rectangle {
                            radius: 3
                            anchors.fill: parent
                            color: "#60eee4da"
                            anchors.leftMargin: 2.5
                            anchors.rightMargin: 2.5
                            anchors.topMargin: 2.5
                            anchors.bottomMargin: 2.5
                        }
                    }
                }
            }

            Repeater {
                id: cellsGrid
                model: grid.columns * grid.rows

                Rectangle {
                    property bool animateMove: false
                    property int x1: -1
                    property int y1: -1
                    property int val: 0
                    property bool pop: false
                    property int prevScale: 0
                    id: cell
                    width: grid.width/grid.columns - 5
                    height: grid.height/grid.rows - 5
                    x: 2.5 + x1*(grid.width/grid.columns)
                    y: 2.5 + y1*(grid.height/grid.rows)
                    color: val == 2    ? "#999eadae" :
                        val == 4    ? "#99718c8e" :
                        val == 8    ? "#e4b301" :
                        val == 16   ? "#e9981f" :
                        val == 32   ? "#e9771f" :
                        val == 64   ? "#e95c1f" :
                        val == 128  ? "#0091bd" :
                        val == 256  ? "#0071bd" :
                        val == 512  ? "#0052bd" :
                        val == 1024 ? "#a300bd" :
                        val == 2048 ? "#db007e" :
                                      "#cc0023" // 4096
                    scale: val ? (pop ? 1.1 : 1) : 0
                    radius: 3
                    visible: ((x1 != -1) && (y1 !=-1))
                    onScaleChanged: if (scale >= 1.1) pop = false

                    Behavior on x { enabled: animateMove; NumberAnimation { duration: 100} }
                    Behavior on y { enabled: animateMove; NumberAnimation { duration: 100} }
                    Behavior on scale { NumberAnimation { duration: 100} }
                    Item {
                        anchors.fill: parent
                        transform: Rotation { origin.x: width/2; origin.y: height/2; angle: -45}
                        property alias val: cell.val
                        Text {
                            height: parent.height
                            width: parent.width
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: val <= 9    ? -1 :
                                                        val <= 99   ? 5 :
                                                        val <= 999  ? 9 :
                                                                    14
                            color: "#f9f6f2"
                            text: parent.val
                            scale: parent.scale
                            font.bold: true
                            font.letterSpacing: val > 99 ? -parent.width * 0.004 :
                                                0
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: val <= 9    ? height*0.7 :
                                            val <= 99   ? height*0.6 :
                                            val <= 999  ? height*0.5 :
                                                        height*0.4
                        }
                    }
                }
            }
        }

        MouseArea {
            width: board.width
            height: board.height
            anchors.centerIn: board

            property bool swipeMode: true

            property int threshold: width*0.01
            property string gesture: ""
            property int value: 0
            property bool horizontal: false

            property int initialX: 0
            property int initialY: 0
            property int deltaX: 0
            property int deltaY: 0

            onPressed: {
                gesture = ""
                value = 0
                initialX = 0
                initialY = 0
                deltaX = 0
                deltaY = 0
                initialX = mouse.x
                initialY = mouse.y
            }

            onPositionChanged: {
                deltaX = mouse.x - initialX
                deltaY = mouse.y - initialY
                horizontal = Math.abs(deltaX) > Math.abs(deltaY)
                if (horizontal) value = deltaX
                else value = deltaY
            }

            onReleased: {
                if (!swipeMode) {
                    var centerY = initialY - board.height/2
                    var centerX = initialX - board.width/2
                    horizontal = Math.abs(centerX) > Math.abs(centerY)
                    if (horizontal) value = centerX
                    else value = centerY
                }
                if (value > threshold && horizontal) {
                    gesture = "right"
                } else if (value < -threshold && horizontal) {
                    gesture = "left"
                } else if (value > threshold) {
                    gesture = "down"
                } else if (value < -threshold) {
                    gesture = "up"
                } else {
                    return
                }
                logic.move(gesture)
            }
        }

        Rectangle {
            property string gesture: ""
            focus: true

            Keys.onPressed: {
                event.accepted = true
                if (event.key == Qt.Key_Right) {
                    gesture = "right"
                } else if (event.key == Qt.Key_Left) {
                    gesture = "left"
                } else if (event.key == Qt.Key_Down) {
                    gesture = "down"
                } else if (event.key == Qt.Key_Up) {
                    gesture = "up"
                } else {
                    return
                }
                logic.move(gesture)
            }
        }
    }

    Rectangle {
        id: gameOver
        height: Dims.h(100)
        width: Dims.w(100)
        radius: DeviceSpecs.hasRoundScreen ? width/2 : 0
        visible: false
        opacity: visible ? 0.8 : 0.0
        scale: visible ? 1 : 0
        color: "#000000"
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.InCurve } }
        Label {
            anchors.top: parent.top
            width: parent.width
            height: parent.height*0.8
            //% "Game Over"
            text: qsTrId("id-game-over")
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: Dims.l(10)
        }
        MouseArea {
            TextMetrics {
                id: tryAgainTextMetrics
                font.pixelSize: Dims.l(8)
                //% "Try Again"
                text: qsTrId("id-try-again")
            }

            y: parent.height*0.5
            anchors.horizontalCenter: parent.horizontalCenter
            height: tryAgainTextMetrics.height + Dims.w(12)
            width: tryAgainTextMetrics.width + Dims.h(16)

            onClicked: logic.reset()

            Rectangle {
                anchors.fill: parent
                radius: height/2
                color: parent.pressed ? "#99111111" : "#BB111111"
            }

            Label {
                id: tryAgainText
                anchors.centerIn: parent
                font: tryAgainTextMetrics.font
                text: tryAgainTextMetrics.text
            }
        }
    }
}
