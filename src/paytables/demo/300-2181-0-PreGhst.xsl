<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson,retrievePrizeTable,getType">
				<lxslt:script lang="javascript">
					<![CDATA[
					var debugFeed = [];
					var debugFlag = false;
					var bonusTotal = 0; 
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNamesDesc)
					{
						var scenario = getScenario(jsonContext);
						var gamesData = scenario.split("|");
						var mainGameData = gamesData[0].split(",");
						var bonusGameData = gamesData[1].split(",");
						var prizeNames = (prizeNamesDesc.substring(1)).split(",");
						var convertedPrizeValues = (prizeValues.substring(1)).split("|");

						const turnsQty      = 6;
						const unusedQty     = 3;
						const cellSize      = 30;
						const cellMargin    = 2;
						const cellLineSize  = 10;
						const prizeLineSize = 30;
						const prizeSize     = 150;
						const cellsSideQty  = 7;
						const colGold       = '#ffc800';
						const colGreen      = '#c2f0cb';
						const colRed        = '#fdc6ce';
						const colDarkGold   = '#7f7f00';
						const colDarkGreen  = '#007f00';
						const colDarkRed    = '#ff0000';

						var boxColourStr  = '';
						var canvasCtxStr  = '';
						var canvasIdStr   = '';
						var textColourStr = '';
						var turnSymbolStr = '';
						var r = [];

						// Output Turns table
						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<tr>');
						r.push('<td class="tablehead" style="padding-right:10px">' + getTranslationByName("turn", translations) + '</td>');
						for (var turnIndex = 0; turnIndex < turnsQty; turnIndex++)
						{
							r.push('<td class="tablebody" align="center" style="padding-right:10px">' + (turnIndex+1).toString() + '</td>');
						}
						r.push('<td class="tablebody" colspan="3">' + getTranslationByName("turnUnused", translations) + '</td>');
						r.push('</tr>');
						r.push('<tr>');
						r.push('<td class="tablehead" style="padding-right:10px">' + getTranslationByName("turnSymbol", translations) + '</td>');
						for (var turnIndex = 0; turnIndex < turnsQty+unusedQty; turnIndex++)
						{
							canvasIdStr   = 'mySymbol' + (turnIndex+1).toString();
							turnSymbolStr = 'turnSymbol' + (turnIndex+1).toString();
							canvasCtxStr  = 'canvasContext' + (turnIndex+1).toString();
							boxColourStr  = (turnIndex+1 <= turnsQty) ? colGreen : colRed;
							textColourStr = (turnIndex+1 <= turnsQty) ? colDarkGreen : colDarkRed;

							r.push('<td class="tablebody" align="center">');
							r.push('<canvas id="' + canvasIdStr + '" width="' + (cellSize+2*(cellMargin+1)).toString() + '" height="' + (cellSize+2*(cellMargin+1)).toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + turnSymbolStr + ' = document.getElementById("' + canvasIdStr + '");');
							r.push('var ' + canvasCtxStr + ' = ' + turnSymbolStr + '.getContext("2d");');
							r.push(canvasCtxStr + '.font = "bold 14px Arial";');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');
							r.push(canvasCtxStr + '.strokeRect(' + cellMargin.toString() + ', ' + cellMargin.toString() + ', ' + cellSize.toString() + ', ' + cellSize.toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + boxColourStr + '";');
							r.push(canvasCtxStr + '.fillRect(' + (cellMargin+1).toString() + ', ' + (cellMargin+1).toString() + ', ' + (cellSize-2).toString() + ', ' + (cellSize-2).toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + textColourStr + '";');
							r.push(canvasCtxStr + '.fillText("' + mainGameData[1][turnIndex] + '", ' + (cellSize/2+cellMargin).toString() + ', ' + (cellSize/2+cellMargin).toString() + ');');
							r.push('</script>');
							r.push('</td>');
						}
						r.push('</tr>');
						r.push('<tr>');
						r.push('<td class="tablehead" style="padding-right:10px">' + getTranslationByName("turnBonusSymb", translations) + '</td>');
						for (var turnIndex = 0; turnIndex < turnsQty; turnIndex++)
						{
							r.push('<td class="tablebody" style="padding-right:10px">' + getTranslationByName(GetBonusSymbText(mainGameData[2][turnIndex]), translations) + '</td>');
						}
						r.push('</tr>');
						r.push('<tr>');
						r.push('<td>&nbsp;</td>');
						r.push('</tr>');
						r.push('</table>');

						const winPaths       = [[[ 0, 1, 2, 3, 4, 5, 6], [ 0, 1, 2, 3,11,12,13], [ 0, 1, 2, 3,11,12,20], [ 7, 8, 9, 3, 4, 5, 6], [ 7, 8, 9, 3,11,12,13], [ 7, 8, 9, 3,11,12,20],
						                         [14,15,16,17,18,12,13], [14,15,16,17,18,12,20], [14,15,23,24,25,26,27], [14,15,23,31,32,33,34], [14,15,23,31,32,40,41], [14,15,23,31,32,40,48],
												 [21,15,16,17,18,12,13], [21,15,16,17,18,12,20], [21,15,23,24,25,26,27], [21,15,23,31,32,33,34], [21,15,23,31,32,40,41], [21,15,23,31,32,40,48],
												 [28,29,23,24,25,26,27], [28,29,23,31,32,33,34], [28,29,23,31,32,40,41], [28,29,23,31,32,40,48], [35,36,37,38,32,33,34], [35,36,37,38,32,40,41],
												 [35,36,37,38,32,40,48], [42,43,44,45,46,40,41], [42,43,44,45,46,40,48]],
						                        [[ 0, 1, 2, 3, 4, 5, 6], [ 0, 1, 2, 3,11,12,13], [ 0, 1, 2, 3,11,12,20], [ 7, 8, 9, 3, 4, 5, 6], [ 7, 8, 9, 3,11,12,13], [ 7, 8, 9, 3,11,12,20],
												 [14,15,16,17,18,12,13], [14,15,16,17,18,12,20], [14,15,16,17,18,26,27], [21,22,23,24,18,12,13], [21,22,23,24,18,12,20], [21,22,23,24,18,26,27],
												 [21,22,23,31,32,33,34], [28,29,23,24,18,12,13], [28,29,23,24,18,12,20], [28,29,23,24,18,26,27], [28,29,23,31,32,33,34], [28,29,37,38,39,40,41],
												 [28,29,37,38,46,47,48], [35,29,23,24,18,12,13], [35,29,23,24,18,12,20], [35,29,23,24,18,26,27], [35,29,23,31,32,33,34], [35,29,37,38,39,40,41],
												 [35,29,37,38,46,47,48], [42,43,44,38,39,40,41], [42,43,44,38,46,47,48]],
												[[ 0, 1, 2, 3, 4, 5, 6], [ 0, 1, 2, 3, 4, 5,13], [ 7, 8, 9,10,11, 5, 6], [ 7, 8, 9,10,11, 5,13], [ 7, 8, 9,10,11,19,20], [14,15,16,17,11, 5, 6],
												 [14,15,16,17,11, 5,13], [14,15,16,17,11,19,20], [14,15,16,24,25,26,27], [21,22,16,17,11, 5, 6], [21,22,16,17,11, 5,13], [21,22,16,17,11,19,20],
												 [21,22,16,24,25,26,27], [21,22,30,31,32,33,34], [21,22,30,31,32,33,41], [28,22,16,17,11, 5, 6], [28,22,16,17,11, 5,13], [28,22,16,17,11,19,20],
												 [28,22,16,24,25,26,27], [28,22,30,31,32,33,34], [28,22,30,31,32,33,41], [35,36,37,38,39,33,34], [35,36,37,38,39,33,41], [35,36,37,38,46,47,48],
												 [42,43,44,38,39,33,34], [42,43,44,38,39,33,41], [42,43,44,38,46,47,48]]];

						const twinCells      = [[3,12,15,23,32,40], [3,12,18,23,29,38], [5,11,16,22,33,38]];

						var winLineCells     = [];
						var prizeLines       = [];
						var cellIndex        = 0;
						var cellHeight       = 0;
						var cellXPos         = 0;
						var cellYPos         = 0;
						var cellTextXPos     = 0;
						var cellTextYPos     = 0;
						var cellTextYOffset  = 0;
						var prizeXPos        = 0;
						var gridLayout       = 0;
						var isTwinCell       = false;
						var isWinCell        = false;
						var isPlaySymb       = false;
						var isTwinCellBottom = false;
						var isWinLine        = false;
						var playSymb         = '';

						// Find win lines and prizes
						gridLayout = parseInt(mainGameData[3]) - 1;

						for (var winLineIndex = 0; winLineIndex < 27; winLineIndex++)
						{
							isWinLine = true;

							for (var winLineCellIndex = 0; winLineCellIndex < cellsSideQty; winLineCellIndex++)
							{
								if (mainGameData[4][winPaths[gridLayout][winLineIndex][winLineCellIndex]] > turnsQty)
								{
									isWinLine = false;
									break;
								}
							}

							if (isWinLine)
							{
								for (var winLineCellIndex = 0; winLineCellIndex < cellsSideQty; winLineCellIndex++)
								{
									winLineCells.push(winPaths[gridLayout][winLineIndex][winLineCellIndex]);
								}

								prizeLines.push((winPaths[gridLayout][winLineIndex][cellsSideQty-1] + 1) / cellsSideQty - 1);
							}
						}

						// Output Main Game
						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<tr>');
						r.push('<td class="tablehead">' + getTranslationByName("mainGame", translations) + '</td>');
						r.push('</tr>');
						r.push('</table>');

						r.push('<canvas id="myGrid" width="470" height="300"></canvas>');
						r.push('<script>');
						r.push('var gridCanvas = document.getElementById("myGrid");');
						r.push('var canvasContext = gridCanvas.getContext("2d");');
						r.push('canvasContext.font = "bold 14px Arial";');
						r.push('canvasContext.textAlign = "center";');
						r.push('canvasContext.textBaseline = "middle";');

						for (var gridRow = 0; gridRow < cellsSideQty; gridRow++)
						{
							for (var gridCol = 0; gridCol < cellsSideQty; gridCol++)
							{
								cellIndex        = gridRow * cellsSideQty + gridCol;
								isTwinCell       = ((twinCells[gridLayout]).indexOf(cellIndex) != -1);
								cellHeight       = (isTwinCell) ? cellSize * 2 + cellLineSize : cellSize;
								cellTextYOffset  = (cellHeight == cellSize) ? 0 : (cellSize + cellLineSize) / 2;
								isWinCell        = (winLineCells.indexOf(cellIndex) != -1);
								isPlaySymb       = (mainGameData[4][cellIndex] <= turnsQty);
								boxColourStr     = (isWinCell) ? colGold : ((isPlaySymb) ? colGreen : colRed);
								textColourStr    = (isWinCell) ? colDarkGold : ((isPlaySymb) ? colDarkGreen : colDarkRed);
								isTwinCellBottom = ((twinCells[gridLayout]).indexOf(cellIndex-cellsSideQty) != -1);
								cellXPos         = cellLineSize + gridCol * (cellSize + cellLineSize);
								cellYPos         = cellLineSize + gridRow * (cellSize + cellLineSize);
								cellTextXPos     = cellXPos + (cellSize / 2);
								cellTextYPos     = cellYPos + (cellSize / 2);
								playSymb         = mainGameData[1][parseInt(mainGameData[4][cellIndex])-1];

								r.push('canvasContext.moveTo(' + (cellXPos-cellLineSize).toString() + ', ' + cellTextYPos.toString() + ');');
								r.push('canvasContext.lineTo(' + cellXPos.toString() + ', ' + cellTextYPos.toString() + ');');
								r.push('canvasContext.stroke();');

								if (!isTwinCellBottom)
								{
									r.push('canvasContext.strokeRect(' + cellXPos.toString() + ', ' + cellYPos.toString() + ', ' + cellSize.toString() + ', ' + cellHeight.toString() +');');
									r.push('canvasContext.fillStyle = "' + boxColourStr + '";');
									r.push('canvasContext.fillRect(' + (cellXPos+1).toString() + ', ' + (cellYPos+1).toString() + ', ' + (cellSize-2).toString() + ', ' + (cellHeight-2).toString() + ');');
									r.push('canvasContext.fillStyle = "' + textColourStr + '";');
									r.push('canvasContext.fillText("' + playSymb + '", ' + cellTextXPos.toString() + ', ' + (cellTextYPos+cellTextYOffset).toString() + ');');
								}
							}

							prizeXPos = (cellSize + cellLineSize) * cellsSideQty + prizeLineSize;

							r.push('canvasContext.moveTo(' + (prizeXPos-prizeLineSize).toString() + ', ' + cellTextYPos.toString() + ');');
							r.push('canvasContext.lineTo(' + prizeXPos.toString() + ', ' + cellTextYPos.toString() + ');');
							r.push('canvasContext.stroke();');

							boxColourStr  = (prizeLines.indexOf(gridRow) != -1) ? colGold : colRed;
							textColourStr = (prizeLines.indexOf(gridRow) != -1) ? colDarkGold : colDarkRed;

							r.push('canvasContext.strokeRect(' + prizeXPos.toString() + ', ' + cellYPos.toString() + ', ' + prizeSize.toString() + ', ' + cellSize.toString() + ');');
							r.push('canvasContext.fillStyle = "' + boxColourStr + '";');
							r.push('canvasContext.fillRect(' + (prizeXPos+1).toString() + ', ' + (cellYPos+1).toString() + ', ' + (prizeSize-2).toString() + ', ' + (cellSize-2).toString() + ');');
							r.push('canvasContext.fillStyle = "' + textColourStr + '";');
							var prizeVal = convertedPrizeValues[getPrizeNameIndex(prizeNames,mainGameData[0][gridRow])].replace(/\t|\r|\n/gm, "");
							r.push('canvasContext.fillText("' + prizeVal + '", ' + (prizeXPos+prizeSize/2).toString() + ', ' + cellTextYPos.toString() + ');');
						//	r.push('canvasContext.fillText("' + convertedPrizeValues[getPrizeNameIndex(prizeNames,mainGameData[0][gridRow])] + '", ' + (prizeXPos+prizeSize/2).toString() + ', ' + cellTextYPos.toString() + ');');
						}
						r.push('</script>');

						if (gamesData[1] != '')
						{
							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
							r.push('<tr>');
							r.push('<td class="tablehead">' + getTranslationByName("bonusSymb1", translations) + '</td>');
							r.push('</tr>');

							for (var bonusWin = 0; bonusWin < bonusGameData.length-1; bonusWin++)
							{
								r.push('<tr>');
								r.push('<td class="tablebody">' + getTranslationByName("turn", translations) + ' ' + (bonusWin+1).toString() + ' : ' +
																							convertedPrizeValues[getPrizeNameIndex(prizeNames,bonusGameData[bonusWin])] + '</td>');
								r.push('</tr>');
							}

							r.push('<tr>');
							r.push('<td>&nbsp;</td>');
							r.push('</tr>');
							r.push('</table>');
						}

						if (gamesData[2] != '')
						{
							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
							r.push('<tr>');
							r.push('<td class="tablehead">' + getTranslationByName("bonusSymb2", translations) + '</td>');
							r.push('</tr>');
							r.push('<tr>');
							r.push('<td class="tablebody">' + getTranslationByName("multiWin", translations) + ' ' + gamesData[2][1] + '</td>');
							r.push('</tr>');
							r.push('<tr>');
							r.push('<td>&nbsp;</td>');
							r.push('</tr>');
							r.push('</table>');
						}

						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						if(debugFlag)
						{
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
 						{
								if(debugFeed[idx] == "")
									continue;
								r.push('<tr>');
 							r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
 							r.push('</td>');
 						r.push('</tr>');
							}
						r.push('</table>');
						}
						return r.join('');
					}

					// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
					// Output: A string of the specific prize structure for the wagered price point
					function retrievePrizeTable(pricePoints, prizeStructures, wageredPricePoint)
					{
						var pricePointList = pricePoints.split(",");
						var prizeStructStrings = prizeStructures.split("|");


						for(var i = 0; i < pricePoints.length; ++i)
						{
							if(wageredPricePoint == pricePointList[i])
							{
								return prizeStructStrings[i];
							}
						}

						return "";
					}

					// Input: Json document string containing 'scenario' at root level.
					// Output: Scenario value.
					function getScenario(jsonContext)
					{
						// Parse json and retrieve scenario string.
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						// Trim null from scenario string.
						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}

					// Input: Json document string containing 'amount' at root level.
					// Output: Price Point value.
					function getPricePoint(jsonContext)
					{
						// Parse json and retrieve price point amount
						var jsObj = JSON.parse(jsonContext);
						var pricePoint = jsObj.amount;

						return pricePoint;
					}

					// Input: "A,B,C,D,..." and "A"
					// Output: index number
					function getPrizeNameIndex(prizeNames, currPrize)
					{
						for(var i = 0; i < prizeNames.length; ++i)
						{
							if(prizeNames[i] == currPrize)
							{
								return i;
							}
						}
					}

					function GetBonusSymbText(symbData)
					{
						var symbChar = symbData;

						if (symbData == '.')
						{
							symbChar = '0';
						}

						return 'bonusSymb' + symbChar;
					}

					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}

					/////////////////////////////////////////////////////////////////////////////////////////
					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								//registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}

					// Grab Wager Type
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function getType(jsonContext, translations)
					{
						// Parse json and retrieve wagerType string.
						var jsObj = JSON.parse(jsonContext);
						var wagerType = jsObj.wagerType;

						return getTranslationByName(wagerType, translations);
					}
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='wagerType']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="my-ext:getType($odeResponseJson, $translations)" disable-output-escaping="yes" />
						</td>
					</tr>
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<br />			
				
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>

				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>


				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>

			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
