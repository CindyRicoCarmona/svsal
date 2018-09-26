xquery version "3.1";

(:~ 
 : Stats XQuery-Module
 : This module contains the functions for statistics and analysis:
 :   - ...
 :
 : For doc annotation format, see
 : - https://exist-db.org/exist/apps/doc/xqdoc
 :
 : For testing, see
 : - https://exist-db.org/exist/apps/doc/xqsuite
 : - https://en.wikibooks.org/wiki/XQuery/XUnit_Annotations
 :
 : @author Andreas Wagner
 : @author David Glück
 : @author Ingo Caesar
 : @version 1.0
 :
 :)
module namespace stats          = "http://salamanca.school/ns/stats";

declare namespace exist         = "http://exist.sourceforge.net/NS/exist";
declare namespace opensearch    = "http://a9.com/-/spec/opensearch/1.1/";
declare namespace output        = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace sal           = "http://salamanca.school/ns/sal";
declare namespace tei           = "http://www.tei-c.org/ns/1.0";
declare namespace templates     = "http://exist-db.org/xquery/templates";
import module namespace console = "http://exist-db.org/xquery/console";
import module namespace functx  = "http://www.functx.com";
import module namespace config  = "http://salamanca.school/ns/config"                at "config.xqm";
import module namespace sphinx  = "http://salamanca.school/ns/sphinx"                at "sphinx.xql";

declare
function stats:loadListOfLemmata($node as node(), $model as map(*)) as map(*) {
    map { 'listOfLemmata' := doc($config:data-root || "/lemmata-97.xml")//sal:lemma[@type='term'][position() le $config:stats-limit] }
};

declare
function stats:lemmaCount($node as node(), $model as map (*), $lang as xs:string?) {
    <span>{concat($model('test'), count($model('listOfLemmata')))}</span>
};

declare
function stats:loadSingleLemmaStats($node as node(), $model as map (*), $lang as xs:string?) {
    map { 'currentLemma' := $model('listOfLemmata') }
};

(: ToDo :)
(: All: Number of occurrences / in number of different works :)
declare
    %templates:wrap
    %templates:default("wid", "W0013")
function stats:singleLemmaStats($node as node(), $model as map (*), $wid as xs:string?, $lang as xs:string?) {

    let $currentLemma          := $model('currentLemma')
  (:    let $currentLemmaHTML   := replace(replace(replace(translate($currentLemma, ' ', '+'), '|', '&#124;'), '(', '&#40;'), ')', '&#41;'):)
    let $currentSearch         := sphinx:search($node, $model, $currentLemma, 'corpus-nogroup', 0, 200)
    let $currentOccurrencesCount := if (count($currentSearch("results")//terms) = 1) then
                                        $currentSearch("results")//terms/hits/text()
                                    else
                                        sum($currentSearch("results")//terms/hits/text())

    let $currentSectionsCount  := xs:int($currentSearch("results")//*:totalResults)
    let $currentWorksCount     := count(distinct-values($currentSearch("results")//item/work/text()))
    let $distribution          := <span title="({if ($currentOccurrencesCount) then 'number of occurrences/' else ()}number of sections containing the occurrences/number of works containing the sections)">
                                    {concat((if ($currentOccurrencesCount) then concat($currentOccurrencesCount, '/') else ()), $currentSectionsCount, '/', $currentWorksCount)}
                                  </span>
    let $cooccurrences         := if ($currentSectionsCount gt 0) then
                                     for $secondLemmaRaw in $model('listOfLemmata')
                                         let $secondLemma           := $secondLemmaRaw
    (:                                     let $secondLemmaHTML     := replace(replace(replace(translate($secondLemma, ' ', '+'), '|', '&#124;'), '(', '&#40;'), ')', '&#41;'):)
                                         let $secondSearch          := sphinx:search($node, $model, concat('(', $currentLemma, ') (', $secondLemma, ')'), 'corpus-nogroup', 0, 20)
                                         let $secondSectionsCount   := xs:int($secondSearch("results")//*:totalResults)
                                         let $secondWorksCount      := count(distinct-values($secondSearch("results")//item/work/text()))
                                         where (($secondSectionsCount gt 0) and ($secondLemma ne $currentLemma))
                                         order by $secondSectionsCount descending
                                         return <a href='search.html?field=corpus&amp;q={encode-for-uri(concat('(', $currentLemma, ') (', $secondLemma, ')'))}&amp;action=Search'><sal:secondLemma lemma="{$secondLemma}" count="{$secondSectionsCount}">{$secondLemma}</sal:secondLemma> <span title="(number of sections/number of works containing the sections)">({$secondSectionsCount}/{$secondWorksCount})</span></a>
                                   else ()


  (:    let $intraWorkDistribution := :)
  (:                                href="#details_{translate(replace($currentLemma, ' | ', '|'), ' ', '+')}":)
    let $detailsLink    :=  <a  class="toggleDetails"
                                data-target="#details_{translate(replace($currentLemma, ' | ', '|'), ' ', '+')}"
                                data-toggle="collapse">Frequenz von '{$currentLemma}' in W0013 <i class="fa fa-chevron-down"aria-hidden="true"></i>
                            </a>
    let $detailsHTML    :=  <span>
                                {$detailsLink}<br/>
                                <iframe  style='width: 80%; height: 300px'
                                         src='//voyant-tools.org/tool/Trends/?stopList=keywords-1e40893403831dbd0a5ce8b94b7da6f7&amp;withDistributions=raw&amp;bins=30&amp;query={encode-for-uri(replace($currentLemma, ' | ', ' '))}&amp;docIndex=0&amp;mode=document&amp;corpus=c0c28e98246c4e145700560a15e4fd53'
                                         id="details_{translate(replace($currentLemma, ' | ', '|'), ' ', '+')}"
                                         class="resultsDetails"><!-- collapse -->
                                </iframe> <!-- &amp;withDistributions=raw -->
                            </span>


    return  <sal:stats><p>
                <b><a href="search.html?field=everything&amp;q={encode-for-uri($currentLemma)}&amp;action=Search">
                    <sal:leadingLemma>{$currentLemma}</sal:leadingLemma>
                   </a>
                   {$distribution}: </b>
                {for $item in $cooccurrences where ($item/position() le count($model('listOfLemmata'))) return <span>{$item}; </span>}
                <br/>
                {$detailsHTML}
            </p></sal:stats>
};
