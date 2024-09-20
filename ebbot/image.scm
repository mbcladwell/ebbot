(define-module (babweb lib image) 
 #:use-module (web client)
#:use-module (srfi srfi-19) ;; date time
#:use-module (srfi srfi-1)  ;;list searching; delete-duplicates in list 
#:use-module (srfi srfi-9)  ;;records
#:use-module (web response)
#:use-module (web request)
#:use-module (web uri)
#:use-module (web client)
#:use-module (web http)
#:use-module (ice-9 rdelim)
#:use-module (ice-9 popen)
#:use-module (ice-9 regex) ;;list-matches
#:use-module (ice-9 receive)	     
#:use-module (ice-9 string-fun)  ;;string-replace-substring
#:use-module (ice-9 pretty-print)
#:use-module (ice-9 binary-ports)
#:use-module (ice-9 ftw)
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
#:use-module (rnrs io ports)
#:use-module (ice-9 textual-ports)
#:use-module (gcrypt base64)
#:use-module (babweb lib env)
#:use-module (babweb lib twitter)
#:use-module (babweb lib utilities)
;;#:use-module (ebbot)

#:export (upload-image
	  oauth1-upload-media-init
	  get-image))

;; (define *oauth-consumer-key* "sHbODSbXeHaV6lV3HvGVRRmfD")
;; (define *oauth-consumer-secret* "if9ZzqTzYnD2hQbDWYqr4vU96Kbxa4J4LnU96FNybGSEXT0fmp")
;; (define *bearer-token* "AAAAAAAAAAAAAAAAAAAAAENdbwEAAAAAK8xNPdkooUQG8UW2skHuRhgnaDo%3D6vkZYbDATcAgTBflgdz1Ng8MPT4qbTV12gh3RUjpt7YAxZj8pM")  ;;this does not change
;; (define *oauth-access-token* "1516431938848006149-ZmM56NXft0k4rieBIH3Aj8A5727ALH")
;; (define *oauth-token-secret* "0Dxm5RXqRUR880NpXCLVekAfU50dcAbTvso6nlzHSQALy")
;; (define *client-id* "SU1SQUh1a2VWNU5GQjFFT2hzLWU6MTpjaQ")
;; (define *client-secret* "ZZGJ5kPWnnkqCtqls8HJDGwyKKAi6cf6TbKnDY7XCzPQQN-pIy")

(define *oauth-consumer-key* (@@ (babweb lib env) *oauth-consumer-key*))
(define *oauth-consumer-secret* (@@ (babweb lib env) *oauth-consumer-secret*))
(define *bearer-token* (@@ (babweb lib env) *bearer-token*))  ;;this does not change
(define *oauth-access-token* (@@ (babweb lib env) *oauth-access-token*))
(define *oauth-token-secret* (@@ (babweb lib env) *oauth-token-secret*))
(define *client-id* (@@ (babweb lib env) *client-id*))
(define *client-secret* (@@ (babweb lib env) *client-secret*))


(define (oauth1-upload-media-finalize media-id )
  ;;Requires authentication? 	Yes (user context only)
  ;;https://developer.twitter.com/en/docs/authentication/oauth-1-0a/authorizing-a-request
  ;;https://developer.twitter.com/en/docs/authentication/oauth-1-0a/creating-a-signature
  (let* (
	 (oauth1-response (make-oauth1-response *oauth-access-token* *oauth-token-secret* '(("user_id" . "1516431938848006149") ("screen_name" . "eddiebbot")))) ;;these credentials do not change
	 (credentials (make-oauth1-credentials *oauth-consumer-key* *oauth-consumer-secret*))
 	 (uri  "https://upload.twitter.com/1.1/media/upload.json")
	 (tweet-request (make-oauth-request uri 'POST '()))
	 (dummy (oauth-request-add-params tweet-request `( 
	  						   (oauth_consumer_key . ,*oauth-consumer-key*)
							   (oauth_nonce . ,(get-nonce 20 ""))
							   (oauth_timestamp . ,(oauth1-timestamp))
							   (oauth_token . ,*oauth-access-token*)
							   (oauth_version . "1.0")
							    (command . "FINALIZE")
					      		    (media_id . ,media-id)							  
							   )))
	 (dummy (oauth1-request-sign tweet-request credentials oauth1-response #:signature oauth1-signature-hmac-sha1))
	 )
    (oauth2-http-request tweet-request #:body #f )
;tweet-request
    ))

;; (define (oauth1-upload-media-simple  file image-type)
;;   ;;Requires authentication? 	Yes (user context only)
;;   ;;https://developer.twitter.com/en/docs/authentication/oauth-1-0a/authorizing-a-request
;;   ;;https://developer.twitter.com/en/docs/authentication/oauth-1-0a/creating-a-signature
;;   (let* (
;; 	 (oauth1-response (make-oauth1-response *oauth-access-token* *oauth-token-secret* '(("user_id" . "1516431938848006149") ("screen_name" . "eddiebbot")))) ;;these credentials do not change
;; 	 (credentials (make-oauth1-credentials *oauth-consumer-key* *oauth-consumer-secret*))
;;  	 (uri  "https://upload.twitter.com/1.1/media/upload.json")
;; 	 (p (open-input-file file))
;; 	; (bytes (get-bytevector-all p))	 
	
;; 	 (bytes64 (base64-encode (get-bytevector-all p)))
;; 	  (dummy (close-port p))
;; ;	 (h (response-emit bytes #:headers '((content-type image/jpg))))
;; ;	  (dummy (pretty-print (number->string the-jpeg)))
;; 	 (tweet-request (make-oauth-request uri 'POST '()))
;; 	 (dummy (oauth-request-add-params tweet-request `( 
;; 	  						   (oauth_consumer_key . ,*oauth-consumer-key*)
;; 							   (oauth_nonce . ,(get-nonce 20 ""))
;; 							   (oauth_timestamp . ,(oauth1-timestamp))
;; 							   (oauth_token . ,*oauth-access-token*)
;; 							   (oauth_version . "1.0")
;; 							   (media_category . "tweet_image")
;; 							   (media_type . ,image-type)
;; 							 ;  (media_data . ,mymedia)
;; 							 ; (total_bytes . ,total-bytes)
							  						 
;; 							   )))
;; 	 (dummy (oauth1-request-sign tweet-request credentials oauth1-response #:signature oauth1-signature-hmac-sha1))
	
;; 	; (dummy (oauth-request-add-param tweet-request 'media bytes64))
;; 	 )
;;       (system (string-append "curl --cacert ../ca/cacert.pem -XPOST -F ‘data=@/home/mbc/Pictures/totvax.jpeg' --url " (oauth-request-http-url tweet-request )))
  

 ;;   (oauth2-http-request tweet-request #:body #f )
;tweet-request
 ;;   ))


(define (oauth1-upload-media-init  file-name)
  ;;Requires authentication? 	Yes (user context only)
  ;;https://developer.twitter.com/en/docs/authentication/oauth-1-0a/authorizing-a-request
  ;;https://developer.twitter.com/en/docs/authentication/oauth-1-0a/creating-a-signature
  (let* (
	 (size-in-bytes (number->string (stat:size (stat file-name))))
;;	 (oauth1-response (make-oauth1-response *oauth-access-token* *oauth-token-secret* '(("user_id" . "1516431938848006149") ("screen_name" . "eddiebbot")))) ;;these credentials do not change
	 (oauth1-response (make-oauth1-response *oauth-access-token* *oauth-token-secret* '(("user_id" . "856105513800609792") ("screen_name" . "mbcladwell")))) ;;these credentials do not change
	 (_ (pretty-print size-in-bytes))
	 (dummy (pretty-print (string-append "*oauth-access-token*: " *oauth-access-token*)))
	 (suffix (cadr (string-split file-name #\.)))
	 (media-type (string-append "image/" suffix))
	 (credentials (make-oauth1-credentials *oauth-consumer-key* *oauth-consumer-secret*))
 	 (uri  "https://upload.twitter.com/1.1/media/upload.json")
	 (tweet-request (make-oauth-request uri 'POST '()))
	 (dummy (oauth-request-add-params tweet-request `( 
	  						   (oauth_consumer_key . ,*oauth-consumer-key*)
							   (oauth_nonce . ,(get-nonce 20 ""))
							   (oauth_timestamp . ,(oauth1-timestamp))
							   (oauth_token . ,*oauth-access-token*)
							   (oauth_version . "1.0")
							    (command . "INIT")
							  (total_bytes . ,size-in-bytes)
							  (media_type . ,media-type)						 
							  (media_category . "TWEET_IMAGE")						 
							   )))
	 (dummy (oauth1-request-sign tweet-request credentials oauth1-response #:signature oauth1-signature-hmac-sha1))
	 )
       (receive (response body)	       
	  (oauth2-http-request tweet-request #:body #f )
	   (json-string->scm (utf8->string body)))) )
;;	 (assoc-ref  (json-string->scm (utf8->string body)) "media_id_string")) ))


(define (oauth1-upload-media-append media-id media counter)
  ;;Requires authentication? 	Yes (user context only)
  ;;https://developer.twitter.com/en/docs/authentication/oauth-1-0a/authorizing-a-request
  ;;https://developer.twitter.com/en/docs/authentication/oauth-1-0a/creating-a-signature
  (let* (
	 (oauth1-response (make-oauth1-response *oauth-access-token* *oauth-token-secret* '(("user_id" . "1516431938848006149") ("screen_name" . "eddiebbot")))) ;;these credentials do not change
	 (segment-index (number->string counter))
	 (credentials (make-oauth1-credentials *oauth-consumer-key* *oauth-consumer-secret*))
 	 (uri  "https://upload.twitter.com/1.1/media/upload.json")
	 (tweet-request (make-oauth-request uri 'POST '()))
	 (dummy (oauth-request-add-params tweet-request `( 
	  						   (oauth_consumer_key . ,*oauth-consumer-key*)
							   (oauth_nonce . ,(get-nonce 20 ""))
							   (oauth_timestamp . ,(oauth1-timestamp))
							   (oauth_token . ,*oauth-access-token*)
							   (oauth_version . "1.0")
							    (command . "APPEND")
							  
							    (media_id . ,media-id)
							    (media . ,media)
							    (segment_index . ,segment-index)
							   )))
	 (dummy (oauth1-request-sign tweet-request credentials oauth1-response #:signature oauth1-signature-hmac-sha1))
	 )
  ;   (receive (response body)	   
	 (oauth2-http-request tweet-request #:body #f )
   ;    (pretty-print (string-append "============segment-index: " segment-index "=======================\n"))
    ;    (values   (pretty-print response  body   )) )
;tweet-request
    ))

(define (oauth1-upload-media-append-recurse id lst counter)
  ;;list of media chunks
  ;;id: media id
  ;;counter starts at 0
  ;;(oauth1-upload-media-append-recurse "238478273847" all-chunks 0)
  (if (null? (cdr lst))
      (oauth1-upload-media-append id (car lst) counter)
      (begin
      ;; (receive (response body)	       
	(oauth1-upload-media-append id (car lst) counter)
	(set! counter (+ counter 1))
	(oauth1-upload-media-append-recurse id (cdr lst) counter)	
       )))



(define (get-image-chunks bytes lst chunk-size n counter )
  ;;bytes whole image
  ;;size: # chars per chunk
  ;;n number of chunks needed
  ;;counter start at 0
  ;; (get-image-chunks "fjskdjk" '() 2000 n 0)  start counter at 1 i.e. the first tweet
  (if (= counter (- n 1))      	
      (reverse (cons bytes lst))
      (let*((chunk  (substring bytes 0 chunk-size))
	    (rest-bytes  (substring bytes chunk-size (string-length bytes)))
	    (dummy (set! lst (cons chunk lst) ))
	    (dummy (set! counter (+ counter 1)))
	)  
	(get-image-chunks rest-bytes lst chunk-size n counter ))
  ))

(define (chunk-an-image image-file-name chunk-size)
  ;;chunk-size: 2000 for 2000 characters
  (let*( (p (open-input-file image-file-name))	 
	 (bytes64 (base64-encode (get-bytevector-all p)))
	 (dummy (close-port p))

	(nchars (string-length bytes64))
	(nchunks (ceiling (/ nchars chunk-size))) 
	)
  (get-image-chunks bytes64 '() chunk-size nchunks 0 )
  ))


(define (oauth1-upload-media-status  id)
  (let* (
;;	 (oauth1-response (make-oauth1-response *oauth-access-token* *oauth-token-secret* '(("user_id" . "1516431938848006149") ("screen_name" . "eddiebbot")))) ;;these credentials do not change	 
	 (oauth1-response (make-oauth1-response *oauth-access-token* *oauth-token-secret* '(("user_id" . "856105513800609792") ("screen_name" . "mbcladwell")))) ;;these credentials do not change	 
	 (credentials (make-oauth1-credentials *oauth-consumer-key* *oauth-consumer-secret*))
 	 (uri  "https://upload.twitter.com/1.1/media/upload.json")
	 (tweet-request (make-oauth-request uri 'GET '()))
	 (dummy (oauth-request-add-params tweet-request `( 
	  						   (oauth_consumer_key . ,*oauth-consumer-key*)
							   (oauth_nonce . ,(get-nonce 20 ""))
							   (oauth_timestamp . ,(oauth1-timestamp))
							   (oauth_token . ,*oauth-access-token*)
							   (oauth_version . "1.0")
							   (command . "STATUS")
							   (media_id . ,id)
							   )))
	 (dummy (oauth1-request-sign tweet-request credentials oauth1-response #:signature oauth1-signature-hmac-sha1))
	 )
     ;;  (receive (response body)	       
	  (oauth2-http-request tweet-request #:body #f )
;;	 (assoc-ref  (json-string->scm (utf8->string body)) "media_id_string"))

    ))


(define (upload-image img-file chunk-size)
  ;;main method for uploading an image file - processes throught init, append, finalize
  ;;returns the media id
  ;;img-file is the path to the image
  ;;chunk-size is the number of base64 characters per chunk, 2000 for twitter
 ;;returns: ((media-id . "1531607694968246272")(file-name . "/home/mbc/projects/bab/memes/prop2.png")(expires . 1654085152))

  (let* ((all-chunks (chunk-an-image img-file chunk-size ))
	 (media-id (oauth1-upload-media-init  img-file))
;;	 (_ (pretty-print (string-append "media-id: " media-id)))
	 (dummy  (oauth1-upload-media-append-recurse  media-id all-chunks 0 ))
	 (body  (receive (response body)		     
		     (oauth1-upload-media-finalize media-id )
		   (json-string->scm (utf8->string body))))
	 (returned-media-id  (assoc-ref  body "media_id_string"))
	 (expires-after-seconds (assoc-ref  body "expires_after_secs"))
	 (expires (+ expires-after-seconds (time-second (current-time))))		
	 )
`(("media-id" . ,returned-media-id)("file-name" . ,img-file)("expires" . ,expires)) ))




;; (define (get-random-image dir)
;;   ;;directory is (string-append working-dir "/random")
;;   (let* ((all-files (list->vector (cddr (scandir dir)) )))
;;    (vector-ref all-files (random (vector-length all-files) (seed->random-state (number->string (time-nanosecond (current-time)))))) ) )

;; (define (get-image directive working-dir)
;;   (cond ((string=? directive "none") (#f))
;; 	((string=? directive "random")(string-append working-dir "/random/" (get-random-image (string-append working-dir "/random/"))) )	
;; 	(else (string-append working-dir "/specific/" directive))
;;      ))
  

;; (define (get-image directive working-dir)
;;   (if (equal? directive "none") #f
;;       (if (equal? directive "random") (string-append working-dir "/random/" (get-random-image (string-append working-dir "/random/")))
;; 	 (string-append working-dir "/specific/" directive) )))  
