(define-module (ebbot twitter) 
 #:use-module (web client)
 #:use-module (srfi srfi-19) ;; date time
 #:use-module (srfi srfi-1)  ;;list searching; delete-duplicates in list 
 #:use-module (srfi srfi-9)  ;;records
 #:use-module (web response)
 #:use-module (web request)
 #:use-module (oop goops) ;; class-of
 #:use-module (web uri)
 #:use-module (web client)
 #:use-module (web http)
 #:use-module (ice-9 rdelim)
 #:use-module (ice-9 i18n)   ;; internationalization
 #:use-module (ice-9 popen)
 #:use-module (ice-9 regex) ;;list-matches
 #:use-module (ice-9 receive)	     
 #:use-module (ice-9 string-fun)  ;;string-replace-substring
 #:use-module (ice-9 pretty-print)
 #:use-module (json)
 #:use-module (oauth oauth1)
 #:use-module (oauth oauth2)
 #:use-module (oauth oauth2 request)
 #:use-module (oauth oauth2 response)
 #:use-module (oauth utils)
 #:use-module (oauth request)
 #:use-module (oauth oauth1 client)
 #:use-module (oauth oauth1 utils)
 #:use-module (oauth oauth1 credentials)
 #:use-module (oauth oauth1 signature)
 #:use-module (rnrs bytevectors)
 #:use-module (ice-9 textual-ports)
 #:use-module (ebbot image)
 #:use-module (gcrypt base64)
 #:export (oauth2-post-tweet
	   oauth1-post-tweet
	   oauth2-post-tweet-recurse
	   oauth1-post-tweet-recurse	   
	   chunk-a-tweet
	   load-vars
	   get-nonce
	   *oauth-consumer-key*
	  *oauth-consumer-secret*
	  *bearer-token*
	  *oauth-access-token*
	  *oauth-token-secret*
	  *client-id*
	  *client-secret*))


(define *oauth-consumer-key* #f)
(define *oauth-consumer-secret* #f)
(define *bearer-token* #f)
(define *oauth-access-token* #f)
(define *oauth-token-secret* #f)
(define *client-id* #f)
(define *client-secret* #f)


(define nonce-chars (list->vector (string->list "ABCDEFGHIJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz123456789")))

(define (load-vars *working-dir*)
(let*  (
	(p  (open-input-file  (string-append *working-dir* "/env.txt")))
 	(a (get-string-all p))
	(b (base64-decode a))
	(varlst (json-string->scm (utf8->string b)))
	)
    (begin
      (set! *oauth-consumer-key* (assoc-ref varlst "oauth-consumer-key"))
      (set! *oauth-consumer-secret* (assoc-ref varlst "oauth-consumer-secret"))
      (set! *bearer-token* (assoc-ref varlst "bearer-token"))
      (set! *oauth-access-token* (assoc-ref varlst "oauth-access-token"))
      (set! *oauth-token-secret* (assoc-ref varlst "oauth-token-secret"))
      (set! *client-id* (assoc-ref varlst "client-id"))
      (set! *client-secret* (assoc-ref varlst "client-secret")))))


(define (get-nonce n s)
  "n is the length of the nonce
   s is the nonce itself (a string)
   therefore to use: (get-nonce 20 "")"
 (if (= n (string-length s))
     s
     (begin
       (set! s (string-append s (string (vector-ref nonce-chars (random 58 (seed->random-state (number->string (time-nanosecond (current-time)))))) )))
       (get-nonce n s))))
  	 
 (define-record-type <response-token>
  (make-response-token token_type access_token)
  response-token?
  (token_type response-token-type)
  (access_token response-token-access-token))

(define oauth-response-token-record (make-response-token "bearer" *oauth-access-token* ))


(define (oauth2-post-tweet  text )
  ;;https://developer.twitter.com/en/docs/authentication/oauth-1-0a/authorizing-a-request
  ;;https://developer.twitter.com/en/docs/authentication/oauth-1-0a/creating-a-signature
  (let* (
	 (oauth1-response (make-oauth1-response *oauth-access-token* *oauth-token-secret* '(("user_id" . "1516431938848006149") ("screen_name" . "eddiebbot")))) ;;these credentials do not change
	 (credentials (make-oauth1-credentials *oauth-consumer-key* *oauth-consumer-secret*))
	 (data (string-append "{\"text\": \"" text "\"}"))
 	 (uri  "https://api.twitter.com/2/tweets")
	 (tweet-request (make-oauth-request uri 'POST '()))
	 (dummy (oauth-request-add-params tweet-request `( 
	  						  (oauth_consumer_key . ,*oauth-consumer-key*)
							 ; (oauth_consumer_secret . ,*oauth-consumer-secret*)
							 ; (oauth_token_secret .,*oauth-token-secret*)
							  (oauth_nonce . ,(get-nonce 20 ""))
							  (oauth_timestamp . ,(oauth1-timestamp))
							
							   (oauth_token . ,*oauth-access-token*)
							   (oauth_version . "1.0")
							   
							  ; (Content-type . "application/json")
							  ; (json . ,data)
							   )))
	 (dummy (oauth1-request-sign tweet-request credentials oauth1-response #:signature oauth1-signature-hmac-sha1))
	 (dummy (oauth-request-add-param tweet-request 'content-type "application/json"))
	 (dummy (oauth-request-add-param tweet-request 'Authorization "Bearer"))
	 (dummy (oauth-request-add-param tweet-request 'scope "tweet.write"))
	 
	 )
(oauth2-http-request tweet-request #:body data )))

(define (get-tweet-chunks txt lst size n counter)
  ;;txt whole tweet
  ;;size: # chars per chunk
  ;;number of chunks
  ;; (get-tweet-chunks "fjskdjk" '() 240 4 1)  start counter at 1 i.e. the first tweet
  (if (= counter n)
      (let*( (tweet (if (= n 1) txt
			(string-append "@eddiebbot " (number->string counter) "/" (number->string n) " " txt))) )	
	  (reverse (cons tweet lst)))
      (let*((tweet1  (substring txt 0 size))
	    (last-space-index (string-rindex tweet1 #\space))
	    
	    (tweet2  (if  (= counter 1)
			 (string-append (number->string counter) "/" (number->string n) " " (substring tweet1 0 last-space-index))
			 (string-append  "@eddiebbot " (number->string counter) "/" (number->string n) " " (substring tweet1 0 last-space-index))
			 ))	    
	    (rest-txt  (substring txt (+ last-space-index 1) (string-length txt)))
	    (dummy (set! lst (cons tweet2 lst) ))
	    (dummy (set! counter (+ counter 1)))
	)  
	(get-tweet-chunks rest-txt lst size n counter))
  ))

(define (chunk-a-tweet text size)
  ;;text: the whole tweet
  ;;size: size of chunks e.g. 280 for twitter
  ;;Split a tweet >280 characters into multiple tweets and number 1/4, 2/4 etc.
  ;;Since the number will take up 4 characters, you have 280 - 4 =276 characters per tweet
  ;;return a list of the individual, numbered tweets in reverse order for tweeting
  (let*((nchars (string-length text))
	(size-mod (- size 4))
	(ntweets (ceiling (/ nchars size-mod)))
	)
  (get-tweet-chunks text '() size-mod ntweets 1) ))


(define (oauth1-post-tweet  text reply-id media-id)
  ;;https://developer.twitter.com/en/docs/authentication/oauth-1-0a/authorizing-a-request
  ;;https://developer.twitter.com/en/docs/authentication/oauth-1-0a/creating-a-signature
  (let* (
	 (dummy (pretty-print text))
	 (dummy (pretty-print reply-id))
	 (dummy (pretty-print media-id))
	 (oauth1-response (make-oauth1-response *oauth-access-token* *oauth-token-secret* '(("user_id" . "1516431938848006149") ("screen_name" . "eddiebbot")))) ;;these credentials do not change
	 (credentials (make-oauth1-credentials *oauth-consumer-key* *oauth-consumer-secret*))
 	 (uri  "https://api.twitter.com/1.1/statuses/update.json")
	 (tweet-request (make-oauth-request uri 'POST '()))
	 (dummy (oauth-request-add-params tweet-request `( 
	  						   (oauth_consumer_key . ,*oauth-consumer-key*)
							   (oauth_nonce . ,(get-nonce 20 ""))
							   (oauth_timestamp . ,(oauth1-timestamp))
							   (oauth_token . ,*oauth-access-token*)
							   (oauth_version . "1.0")
							   (status . ,text)
							   ) ))
	 (dummy (if (string=? reply-id "") #f (oauth-request-add-param tweet-request 'in_reply_to_status_id reply-id) ))
	 (dummy (if (string=? media-id "") #f (oauth-request-add-param tweet-request 'media_ids media-id) ))
	 (dummy (oauth1-request-sign tweet-request credentials oauth1-response #:signature oauth1-signature-hmac-sha1)))
    (oauth1-http-request tweet-request #:body #f #:extra-headers '())))


(define (oauth1-post-tweet-recurse lst reply-id media-id counter)
  ;;list of tweets to post
  ;;reply-id initially ""
  ;;counter initially 0; counter is needed to identify reply-id in first round and use media-id if exists
  (if (null? (cdr lst))
      (oauth1-post-tweet (car lst) reply-id "")
      (if (eqv? counter 0)
	  (begin
	    (receive (response body)	  
		(oauth1-post-tweet (car lst) reply-id media-id)
	       (set! counter (+ counter 1))
	     (oauth1-post-tweet-recurse  (cdr lst) (assoc-ref  (json-string->scm (utf8->string body)) "id_str")  media-id counter))			
	     )
	  (begin
	    (receive (response body)	  
		(oauth1-post-tweet (car lst) reply-id "")
	       (set! counter (+ counter 1))
	     (oauth1-post-tweet-recurse  (cdr lst) (assoc-ref  (json-string->scm (utf8->string body)) "id_str")  "" counter))			
	      ))  ))
       



