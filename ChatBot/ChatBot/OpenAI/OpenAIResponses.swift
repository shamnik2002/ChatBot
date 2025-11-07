//
//  OpenAIResponses.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/16/25.
//

import Foundation

/*
 {
   "id": "resp_07559543f7bfe6170068f1b3ceaf2881a3a81ed96805a10e4f",
   "object": "response",
   "created_at": 1760670670,
   "status": "completed",
   "background": false,
   "billing": {
     "payer": "developer"
   },
   "error": null,
   "incomplete_details": null,
   "instructions": null,
   "max_output_tokens": null,
   "max_tool_calls": null,
   "model": "gpt-5-nano-2025-08-07",
   "output": [
     {
       "id": "rs_07559543f7bfe6170068f1b3cf7ac881a3ba52213f73f84cda",
       "type": "reasoning",
       "summary": []
     },
     {
       "id": "msg_07559543f7bfe6170068f1b3d2705881a3b1fd1021140be0c6",
       "type": "message",
       "status": "completed",
       "content": [
         {
           "type": "output_text",
           "annotations": [],
           "logprobs": [],
           "text": "In a moonlit meadow, a gentle unicorn watched over the sleeping world. It sprinkled stardust from its horn, weaving lullabies that soothed the night and made the flowers dream. When the first light touched the horizon, the unicorn curled beneath a silver leaf and drifted off to dream of tomorrow's adventures."
         }
       ],
       "role": "assistant"
     }
   ],
   "parallel_tool_calls": true,
   "previous_response_id": null,
   "prompt_cache_key": null,
   "reasoning": {
     "effort": "medium",
     "summary": null
   },
   "safety_identifier": null,
   "service_tier": "default",
   "store": true,
   "temperature": 1.0,
   "text": {
     "format": {
       "type": "text"
     },
     "verbosity": "medium"
   },
   "tool_choice": "auto",
   "tools": [],
   "top_logprobs": 0,
   "top_p": 1.0,
   "truncation": "disabled",
   "usage": {
     "input_tokens": 17,
     "input_tokens_details": {
       "cached_tokens": 0
     },
     "output_tokens": 518,
     "output_tokens_details": {
       "reasoning_tokens": 448
     },
     "total_tokens": 535
   },
   "user": null,
   "metadata": {}
 }
 */
/// OpenAIResponse model for responses API response
/// Output is an array which gives you reasoning and output text
struct OpenAIResponse: Codable {
    let id: String
    let created_at: TimeInterval
    let output: [Output]    
    // TODO: handle API errors
//    let error: ResponseError
//    struct ResponseError: Codable {
//        let code: String
//        let message: String
//    }
    struct Output: Codable {
        let type: String // we care about message
        let id: String
        let role: String? // we need role to visual representation on message belongs to user or the response
        let content: [Content]?
        
        struct Content: Codable {
            let type: String // we care about output_text
            let text: String // actual data from openAI model
        }
    }    
}

enum ChatResponseRole: String, Codable {
    case user // use this for user input
    case assistant // model always returns this
    case system // to display rate limit issues
}


