xquery version "3.1";

(:~ 
 : iiif-admin XQuery executable
 : This file calls the iiif interface with admin/write privileges.
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
~:)

declare         namespace output    = "http://www.w3.org/2010/xslt-xquery-serialization";
declare         namespace request   = "http://exist-db.org/xquery/request";
declare         namespace response  = "http://exist-db.org/xquery/response";
declare         namespace xmldb     = "http://exist-db.org/xquery/xmldb";
import module   namespace console   = "http://exist-db.org/xquery/console";
import module   namespace admin     = "http://salamanca.school/ns/admin"  at "modules/admin.xql";
import module   namespace config    = "http://salamanca.school/ns/config" at "modules/config.xqm";
import module   namespace iiif      = "http://salamanca.school/ns/iiif"   at "modules/iiif.xql";

(:declare option output:method "json";
declare option output:media-type "application/json";:)

(: only monograph manifests or multi-volume collections may be created :)
let $wid                := if (matches(request:get-parameter('resourceId', ''), '^W\d{4}$')) then 
                               request:get-parameter('resourceId', '')
                           else ()
let $header-addition   := response:set-header("Access-Control-Allow-Origin", "*")
let $debug              := if ($config:debug = ("trace", "info")) then console:log("iiif handler running, requested work: '" || $wid || "'.") else ()

let $resource := serialize(iiif:createResource($wid), 
        <output:serialization-parameters>
            <output:method>json</output:method>
        </output:serialization-parameters>)

let $create-collection-status :=     if (not(xmldb:collection-available($config:iiif-root))) then
                                          xmldb:create-collection($config:salamanca-data-root, "iiif")
                                     else ()
let $chmod-collection-status  := xmldb:set-collection-permissions($config:iiif-root, 'sal', 'svsal',  util:base-to-integer(0775, 8))
let $remove-status            := if ($resource and ($wid || '.json') = xmldb:get-child-resources($config:iiif-root)) then
                                      xmldb:remove($config:iiif-root, $wid || '.json')
                                 else ()

let $save := if ($resource) then xmldb:store($config:iiif-root, $wid || '.json', $resource) else ()

return <output><status>Saved at {$save}</status><data>{$resource}</data></output>
