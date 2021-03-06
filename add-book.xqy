xquery version "1.0-ml";

declare option xdmp:output "method = html";

declare function local:saveBook(
    $title as xs:string,
    $author as xs:string?,
    $year as xs:string?,
    $price as xs:string?,
    $category as xs:string?
) as xs:string {

    (:Generates string based off of Host time and random concatinated:)

    let $id as xs:string := local:generateID()
    let $book as element(book) :=
        element book {
            attribute category { $category },
            attribute id { $id },
            element title { $title },
            element author { $author },
            element year { $year },
            element price { $price }
        }

    let $uri := '/bookstore/book-' || $id || '.xml'

    (:Pushes to Marklogic DB here if the book already Exists it Updates, but the URI will always be different so update won't occur:)
    let $save := xdmp:document-insert($uri, $book)


    return


    (:***********WHY RETURN THIS?**********:)
        $id
};

declare function local:generateID(
) as xs:string {
    let $hash :=
        xs:string(
            xdmp:hash64(
                fn:concat(
                    xs:string(xdmp:host()),
                    xs:string(fn:current-dateTime()),
                    xs:string(xdmp:random())
                )
            )
        )
    return
        local:padString($hash, 20, fn:false())
};

declare function local:padString(
    $string as xs:string,
    $length as xs:integer,
    $padLeft as xs:boolean
) as xs:string {
    if (fn:string-length($string) = $length) then (
        $string
    ) else if (fn:string-length($string) < $length) then (
        if ($padLeft) then (
            local:padString(fn:concat("0", $string), $length, $padLeft)
        ) else (
            local:padString(fn:concat($string, "0"), $length, $padLeft)
        )
    ) else (
        fn:substring($string, 1, $length)
    )
};

declare function local:sanitizeInput($chars as xs:string?) {
    fn:replace($chars,"[\]\[<>{}\\();%\+]","")
};

declare variable $id as xs:string? :=

(:***************on post request Sanitize the parameters before sending them off to saveBook :)


    if (xdmp:get-request-method() eq "POST") then (
        (:gets data from input fields HERE!:)
        let $title as xs:string? := local:sanitizeInput(xdmp:get-request-field("title"))
        let $author as xs:string? := local:sanitizeInput(xdmp:get-request-field("author"))
        let $year as xs:string? := local:sanitizeInput(xdmp:get-request-field("year"))
        let $price as xs:string? := local:sanitizeInput(xdmp:get-request-field("price"))
        let $category as xs:string? := local:sanitizeInput(xdmp:get-request-field("category"))
        return

            local:saveBook($title, $author, $year, $price, $category)
    ) else ();


(: build the html :)
xdmp:set-response-content-type("text/html"),
'<!DOCTYPE html>',
<html>
    <head>
        <link rel="stylesheet" type="text/css" href="/css/style.css"/>
        <title>Add Book</title>
    </head>
    <a href="book-display.xqy" >List Library</a><br/>
    <a href="Update.xq" >Update Library</a>
    <body>
        {
        if (fn:exists($id) and $id ne '') then (
            <div class="message">Book Saved! ({$id})</div>
        ) else ()
        }
        <form name="add-book" action="add-book.xqy" method="post">
            <fieldset>
                <legend style="text-align: center">Add Book</legend>
                <label for="title">Title</label> <input type="text" id="title" name="title"/><br/>
                <label for="author">Author</label> <input type="text" id="author" name="author"/><br/>
                <label for="year">Year</label> <input type="text" id="year" name="year"/><br/>
                <label for="price">Price</label> <input type="text" id="price" name="price"/><br/>
                <label for="category">Category</label>
                <select name="category" style=" float:right;" id="category">
                    <option/>
                    {
                    for $c in ('CHILDREN','FICTION','NON-FICTION')
                    return
                        <option value="{$c}">{$c}</option>
                    }
                </select><br/>
                <input type="submit" value="Save" />

            </fieldset>                      
        </form>
    </body>
</html>