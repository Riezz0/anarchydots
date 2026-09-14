import QtQuick

Rectangle {
    id: hadithCard

    property string matnAr: ""
    property string matn: ""
    property string narrator: ""
    property string source: ""
    property string grade: ""
    property string gradeColor: theme.color2
    property string topic: ""
    property var isnad: []
    property bool showFullChain: false
    property bool showArabic: true

    width: 360
    height: Math.min(hadithColumn.implicitHeight + 32, 280)
    radius: rootLock.barRadius
    color: Qt.rgba(theme.background.r, theme.background.g, theme.background.b, 0.85)
    border.color: theme.color3
    border.width: rootLock.popupBorderThickness

    property var hadiths: [
        {
            matnAr: "إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى",
            matn: "Actions are but by intentions, and every person shall have only what they intended.",
            narrator: "Umar ibn al-Khattab",
            source: "Sahih al-Bukhari 1",
            grade: "Sahih",
            gradeColor: theme.color2,
            topic: "Intention (Niyyah)",
            isnad: [
                { name: "Umar ibn al-Khattab", status: "Sahabi" }
            ]
        },
        {
            matnAr: "لاَ يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ",
            matn: "None of you truly believes until he loves for his brother what he loves for himself.",
            narrator: "Anas ibn Malik",
            source: "Sahih al-Bukhari 13",
            grade: "Sahih",
            gradeColor: theme.color2,
            topic: "Faith (Iman)",
            isnad: [
                { name: "Anas ibn Malik", status: "Sahabi" }
            ]
        },
        {
            matnAr: "الْحَلاَلُ بَيِّنٌ وَالْحَرَامُ بَيِّنٌ، وَبَيْنَهُمَا أُمُورٌ مُشْتَبِهَاتٌ لاَ يَعْلَمُهُنَّ كَثِيرٌ مِنَ النَّاسِ",
            matn: "The lawful is clear and the unlawful is clear, and between them are doubtful matters about which many people do not know.",
            narrator: "An-Nu'man ibn Bashir",
            source: "Sahih al-Bukhari 52",
            grade: "Sahih",
            gradeColor: theme.color2,
            topic: "Jurisprudence (Fiqh)",
            isnad: [
                { name: "An-Nu'man ibn Bashir", status: "Sahabi" }
            ]
        },
        {
            matnAr: "مَنْ سَلَكَ طَرِيقاً يَلْتَمِسُ فِيهِ عِلْماً سَهَّلَ اللهُ لَهُ بِهِ طَرِيقاً إِلَى الْجَنَّةِ",
            matn: "Whoever treads a path seeking knowledge, Allah will make easy for him a path to Paradise.",
            narrator: "Abu Hurairah",
            source: "Sahih Muslim 2699",
            grade: "Sahih",
            gradeColor: theme.color2,
            topic: "Knowledge (Ilm)",
            isnad: [
                { name: "Abu Hurairah", status: "Sahabi" }
            ]
        },
        {
            matnAr: "الدُّنْيَا سِجْنُ الْمُؤْمِنِ وَجَنَّةُ الْكَافِرِ",
            matn: "The world is a prison for the believer and a paradise for the disbeliever.",
            narrator: "Mu'adh ibn Jabal",
            source: "Sahih Muslim 2956",
            grade: "Sahih",
            gradeColor: theme.color2,
            topic: "Worldly Life (Dunya)",
            isnad: [
                { name: "Mu'adh ibn Jabal", status: "Sahabi" }
            ]
        },
        {
            matnAr: "اتَّقِ اللهَ حَيْثُمَا كُنْتَ، وَأَتْبِعِ السَّيِّئَةَ الْحَسَنَةَ تَمْحُهَا، وَخَالِقِ النَّاسَ بِخُلُقٍ حَسَنٍ",
            matn: "Fear Allah wherever you are, follow up a bad deed with a good one and it will wipe it out, and behave well towards people.",
            narrator: "Mu'adh ibn Jabal",
            source: "Jami at-Tirmidhi 1987",
            grade: "Hasan",
            gradeColor: theme.color3,
            topic: "Taqwa (God-Consciousness)",
            isnad: [
                { name: "Mu'adh ibn Jabal", status: "Sahabi" }
            ]
        },
        {
            matnAr: "لاَ تَغْضَبْ، لاَ تَغْضَبْ، لاَ تَغْضَبْ",
            matn: "Do not get angry. Do not get angry. Do not get angry.",
            narrator: "Abu Hurairah",
            source: "Sahih al-Bukhari 6116",
            grade: "Sahih",
            gradeColor: theme.color2,
            topic: "Patience (Sabr)",
            isnad: [
                { name: "Abu Hurairah", status: "Sahabi" }
            ]
        },
        {
            matnAr: "لَيْسَ الشَّدِيدُ بِالصُّرَعَةِ، إِنَّمَا الشَّدِيدُ الَّذِي يَمْلِكُ نَفْسَهُ عِنْدَ الْغَضَبِ",
            matn: "The strong person is not the one who can wrestle someone else down. The strong person is the one who can control himself when he is angry.",
            narrator: "Abu Hurairah",
            source: "Sahih al-Bukhari 6114",
            grade: "Sahih",
            gradeColor: theme.color2,
            topic: "Self-Control",
            isnad: [
                { name: "Abu Hurairah", status: "Sahabi" }
            ]
        },
        {
            matnAr: "مَا نَقَصَتْ صَدَقَةٌ مِنْ مَالٍ، وَمَا زَادَ اللهُ عَبْداً بِعَفْوٍ إِلاَّ عِزّاً",
            matn: "No charity ever decreases wealth, and no one forgives another except that Allah increases his honor.",
            narrator: "Abu Hurairah",
            source: "Sahih Muslim 2588",
            grade: "Sahih",
            gradeColor: theme.color2,
            topic: "Charity (Sadaqah)",
            isnad: [
                { name: "Abu Hurairah", status: "Sahabi" }
            ]
        },
        {
            matnAr: "مَنْ لَمْ يَرْحَمِ النَّاسَ لَمْ يَرْحَمْهُ اللهُ",
            matn: "Whoever does not show mercy to people, Allah will not show mercy to him.",
            narrator: "Jarir ibn Abdullah",
            source: "Sahih al-Bukhari 7376",
            grade: "Sahih",
            gradeColor: theme.color2,
            topic: "Mercy (Rahmah)",
            isnad: [
                { name: "Jarir ibn Abdullah", status: "Sahabi" }
            ]
        },
        {
            matnAr: "إِنَّ اللهَ جَمِيلٌ يُحِبُّ الْجَمَالَ",
            matn: "Indeed, Allah is Beautiful and loves beauty.",
            narrator: "Abu Hurairah",
            source: "Sahih Muslim 91",
            grade: "Sahih",
            gradeColor: theme.color2,
            topic: "Beauty (Jamal)",
            isnad: [
                { name: "Abu Hurairah", status: "Sahabi" }
            ]
        },
        {
            matnAr: "الدُّعَاءُ هُوَ الْعِبَادَةُ",
            matn: "Supplication is the essence of worship.",
            narrator: "An-Nu'man ibn Bashir",
            source: "Jami at-Tirmidhi 3372",
            grade: "Hasan",
            gradeColor: theme.color3,
            topic: "Supplication (Du'a)",
            isnad: [
                { name: "An-Nu'man ibn Bashir", status: "Sahabi" }
            ]
        }
    ]

    property int currentHadithIndex: 0

    Component.onCompleted: pickRandomHadith()

    function pickRandomHadith() {
        var idx = Math.floor(Math.random() * hadiths.length)
        currentHadithIndex = idx
        var h = hadiths[idx]
        matnAr = h.matnAr
        matn = h.matn
        narrator = h.narrator
        source = h.source
        grade = h.grade
        gradeColor = h.gradeColor
        topic = h.topic
        isnad = h.isnad
    }

    function nextHadith() {
        currentHadithIndex = (currentHadithIndex + 1) % hadiths.length
        var h = hadiths[currentHadithIndex]
        matnAr = h.matnAr
        matn = h.matn
        narrator = h.narrator
        source = h.source
        grade = h.grade
        gradeColor = h.gradeColor
        topic = h.topic
        isnad = h.isnad
    }

    Timer {
        interval: 300000
        running: true
        repeat: true
        onTriggered: hadithCard.pickRandomHadith()
    }

    property bool isLongText: hadithColumn.implicitHeight + 32 > 500

    Flickable {
        id: scrollArea
        anchors.fill: parent
        anchors.margins: 16
        contentHeight: hadithColumn.implicitHeight
        clip: true
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds
        opacity: 1

        property real scrollStartY: 0
        property bool isScrolling: false

        Timer {
            id: autoScrollTimer
            interval: 50
            running: hadithCard.isLongText
            repeat: true
            property real scrollPos: 0
            property bool scrollingDown: true
            property int pauseCount: 0
            onTriggered: {
                if (scrollArea.contentHeight <= scrollArea.height) {
                    stop()
                    return
                }
                if (pauseCount > 0) {
                    pauseCount--
                    return
                }
                if (scrollingDown) {
                    scrollPos += 1
                    if (scrollPos >= scrollArea.contentHeight - scrollArea.height) {
                        scrollingDown = false
                        pauseCount = 40
                    }
                } else {
                    scrollPos -= 1
                    if (scrollPos <= 0) {
                        scrollingDown = true
                        pauseCount = 40
                    }
                }
                scrollArea.contentY = scrollPos
            }
        }

        Column {
            id: hadithColumn
            width: scrollArea.width
            spacing: 10

            // Header row - Topic + Grade + buttons
            Row {
                width: parent.width
                spacing: 6

                Rectangle {
                    width: topicLabel.implicitWidth + 14
                    height: 22
                    radius: 6
                    color: Qt.rgba(theme.color3.r, theme.color3.g, theme.color3.b, 0.2)
                    Text {
                        id: topicLabel
                        anchors.centerIn: parent
                        text: hadithCard.topic
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                        font.bold: true
                        color: theme.color3
                    }
                }

                Rectangle {
                    width: gradeLabel.implicitWidth + 14
                    height: 22
                    radius: 6
                    color: Qt.rgba(hadithCard.gradeColor.r, hadithCard.gradeColor.g, hadithCard.gradeColor.b, 0.2)
                    Text {
                        id: gradeLabel
                        anchors.centerIn: parent
                        text: hadithCard.grade
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                        font.bold: true
                        color: hadithCard.gradeColor
                    }
                }

                Item { width: 4; height: 1 }

                // Arabic toggle
                Rectangle {
                    width: 26; height: 26; radius: 6
                    color: hadithCard.showArabic ? Qt.rgba(theme.color4.r, theme.color4.g, theme.color4.b, 0.2) : "transparent"
                    border.color: hadithCard.showArabic ? theme.color4 : "transparent"
                    border.width: 2
                    Text {
                        anchors.fill: parent
                        anchors.verticalCenterOffset: -6
                        text: "AR"
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                        font.bold: true
                        color: hadithCard.showArabic ? theme.color4 : theme.color7
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: hadithCard.showArabic = !hadithCard.showArabic
                    }
                }

                // Next
                Rectangle {
                    width: 26; height: 26; radius: 6
                    color: nextArea.containsMouse ? Qt.rgba(theme.color7.r, theme.color7.g, theme.color7.b, 0.2) : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "→"
                        font.pixelSize: 16
                        font.family: "JetBrainsMono Nerd Font"
                        color: theme.foreground
                    }
                    MouseArea {
                        id: nextArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: hadithCard.nextHadith()
                    }
                }
            }

            // Divider
            Rectangle {
                width: parent.width
                height: 1
                color: Qt.rgba(theme.color8.r, theme.color8.g, theme.color8.b, 0.3)
            }

            // Arabic matn
            Text {
                visible: hadithCard.showArabic && hadithCard.matnAr.length > 0
                width: parent.width
                text: hadithCard.matnAr
                font.pixelSize: 36
                font.family: "Lateef"
                color: theme.foreground
                wrapMode: Text.WordWrap
                lineHeight: 1.6
                horizontalAlignment: Text.AlignRight
            }

            // English matn
            Text {
                width: parent.width
                text: hadithCard.matn
                font.pixelSize: 12
                font.family: "JetBrainsMono Nerd Font"
                color: Qt.rgba(theme.foreground.r, theme.foreground.g, theme.foreground.b, 0.8)
                wrapMode: Text.WordWrap
                lineHeight: 1.4
            }

            // Narrator
            Row {
                spacing: 6
                Text {
                    text: "Narrated by"
                    font.pixelSize: 10
                    font.family: "JetBrainsMono Nerd Font"
                    color: theme.color7
                }
                Text {
                    text: hadithCard.narrator
                    font.pixelSize: 10
                    font.family: "JetBrainsMono Nerd Font"
                    font.bold: true
                    color: theme.color4
                }
            }

            // Source
            Row {
                spacing: 6
                Text {
                    text: "Source:"
                    font.pixelSize: 10
                    font.family: "JetBrainsMono Nerd Font"
                    color: theme.color7
                }
                Text {
                    text: hadithCard.source
                    font.pixelSize: 10
                    font.family: "JetBrainsMono Nerd Font"
                    color: theme.color5
                }
            }

            // Isnad chain (expandable)
            Rectangle {
                width: parent.width
                height: showFullChain ? isnadColumn.implicitHeight + 20 : 28
                radius: 6
                color: Qt.rgba(theme.color8.r, theme.color8.g, theme.color8.b, 0.15)
                clip: true

                Behavior on height { NumberAnimation { duration: 200 } }

                Column {
                    id: isnadColumn
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    Row {
                        width: parent.width
                        Text {
                            text: "Isnad (Chain of Narration)"
                            font.pixelSize: 10
                            font.family: "JetBrainsMono Nerd Font"
                            font.bold: true
                            color: theme.color6
                        }
                        Item { width: parent.width - 170; height: 1 }
                        Text {
                            text: hadithCard.showFullChain ? "󰁅" : "󰁣"
                            font.pixelSize: 14
                            font.family: "JetBrainsMono Nerd Font"
                            color: theme.color7
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: hadithCard.showFullChain = !hadithCard.showFullChain
                            }
                        }
                    }

                    Repeater {
                        model: hadithCard.showFullChain ? hadithCard.isnad : []
                        Row {
                            spacing: 6
                            Rectangle {
                                width: 8; height: 8; radius: 4
                                color: modelData.status === "Sahabi" ? theme.color2
                                    : modelData.status === "Thiqah" ? theme.color4
                                    : modelData.status === "Hasan" ? theme.color3 : theme.color7
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: modelData.name
                                font.pixelSize: 10
                                font.family: "JetBrainsMono Nerd Font"
                                color: theme.foreground
                            }
                            Text {
                                text: "(" + modelData.status + ")"
                                font.pixelSize: 9
                                font.family: "JetBrainsMono Nerd Font"
                                color: theme.color7
                            }
                        }
                    }
                }
            }

            // Scroll indicator
            Text {
                visible: hadithCard.isLongText
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Scroll for more 󰄽"
                font.pixelSize: 9
                font.family: "JetBrainsMono Nerd Font"
                color: theme.color7
                opacity: 0.6
            }
        }
    }
}
